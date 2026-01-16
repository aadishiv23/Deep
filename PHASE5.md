# Phase 5: File Indexing + Search - Implementation Guide

## Architecture

**Approach**: Multiple Indexers → Single SearchStore (GRDB + FTS5) → Single FileSearchProvider

```
┌─────────────────┐
│  FileIndexer    │──┐
│ (user folders)  │  │
└─────────────────┘  │
                     │    ┌──────────────┐    ┌────────────────────┐
┌─────────────────┐  ├───→│ SearchStore  │←───│ FileSearchProvider │←── User Query
│  AppsIndexer    │──┤    │ (GRDB+FTS5)  │    └────────────────────┘
│ (/Applications) │  │    └──────────────┘
└─────────────────┘  │
                     │
┌─────────────────┐  │
│ RecentsTracker  │──┘
│ (system + app)  │
└─────────────────┘
```

## Key Decisions

| Decision | Choice |
|----------|--------|
| SQLite Library | GRDB.swift |
| Content Indexing | Yes - text/code files (FTS5) |
| Index Trigger | On app launch (background) |
| Recents Source | Both NSDocumentController + track opens in Deep |

---

## File Structure

```
Deep/
├── Storage/
│   ├── SearchStore.swift              # GRDB actor (singleton)
│   └── Models/
│       └── IndexedFile.swift          # GRDB record type
│
├── Indexing/
│   ├── Coordinator/
│   │   └── IndexingCoordinator.swift  # Orchestrates all indexers
│   ├── Indexers/
│   │   ├── FileIndexer.swift          # User folder streaming traversal
│   │   ├── AppsIndexer.swift          # /Applications scan
│   │   └── ContentExtractor.swift     # Text/code content extraction
│   └── Tracking/
│       └── RecentsTracker.swift       # Dual recents tracking
│
└── Search/
    └── Services/
        └── Providers/
            └── FileSearchProvider.swift  # Queries SearchStore
```

---

## Implementation Order

### Step 1: Add GRDB Dependency
- Open `Deep.xcodeproj`
- File > Add Package Dependencies
- URL: `https://github.com/groue/GRDB.swift`
- Version: Up to Next Major

### Step 2: Create Storage Layer
1. `IndexedFile.swift` - GRDB record model
2. `SearchStore.swift` - Actor with schema + FTS5 + migrations + CRUD

### Step 3: Create Indexers
3. `ContentExtractor.swift` - Extract text from code/doc files
4. `FileIndexer.swift` - Streaming traversal, metadata extraction, batch writes
5. `AppsIndexer.swift` - Scan /Applications + ~/Applications
6. `RecentsTracker.swift` - NSDocumentController + internal tracking

### Step 4: Create Coordinator
7. `IndexingCoordinator.swift` - Orchestrates all indexers, progress reporting

### Step 5: Create Search Provider
8. `FileSearchProvider.swift` - Implements `SearchProviding`, queries FTS5

### Step 6: Wire Up
9. `AppDelegate.swift` - Start indexing on launch
10. `ViewModel` - Use `FileSearchProvider` instead of `StubSearchProvider`

---

## Database Schema

### files Table
```sql
CREATE TABLE files (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    path TEXT UNIQUE NOT NULL,
    title TEXT NOT NULL,
    subtitle TEXT NOT NULL,
    type TEXT NOT NULL,
    size INTEGER NOT NULL,
    modifiedDate DATETIME NOT NULL,
    createdDate DATETIME NOT NULL,
    contentHash TEXT,
    isRecent BOOLEAN DEFAULT 0,
    accessCount INTEGER DEFAULT 0,
    lastAccessed DATETIME
);
```

### FTS5 Virtual Table
```sql
CREATE VIRTUAL TABLE files_fts USING fts5(
    title, subtitle, content, path,
    content='files',
    content_rowid='id',
    tokenize='porter unicode61'
);
```

### Triggers (Keep FTS in Sync)
```sql
CREATE TRIGGER files_ai AFTER INSERT ON files BEGIN
    INSERT INTO files_fts(rowid, title, subtitle, content, path)
    VALUES (new.id, new.title, new.subtitle, '', new.path);
END;

CREATE TRIGGER files_ad AFTER DELETE ON files BEGIN
    INSERT INTO files_fts(files_fts, rowid, title, subtitle, content, path)
    VALUES ('delete', old.id, old.title, old.subtitle, '', old.path);
END;

CREATE TRIGGER files_au AFTER UPDATE ON files BEGIN
    INSERT INTO files_fts(files_fts, rowid, title, subtitle, content, path)
    VALUES ('delete', old.id, old.title, old.subtitle, '', old.path);
    INSERT INTO files_fts(rowid, title, subtitle, content, path)
    VALUES (new.id, new.title, new.subtitle, '', new.path);
END;
```

### Indexes
```sql
CREATE INDEX idx_files_path ON files(path);
CREATE INDEX idx_files_type ON files(type);
CREATE INDEX idx_files_modified ON files(modifiedDate);
CREATE INDEX idx_files_recent ON files(isRecent, lastAccessed);
```

---

## Code Implementation

### 1. IndexedFile.swift

**Location**: `Deep/Storage/Models/IndexedFile.swift`

```swift
import Foundation
import GRDB

/// GRDB record type representing an indexed file in the database.
struct IndexedFile: Codable, FetchableRecord, PersistableRecord {

    // MARK: - Properties

    var id: Int64?
    let path: String
    let title: String
    let subtitle: String
    let type: String  // Maps to ResultType.rawValue
    let size: Int64
    let modifiedDate: Date
    let createdDate: Date
    var contentHash: String?
    var isRecent: Bool
    var accessCount: Int
    var lastAccessed: Date?

    // MARK: - Table Name

    static var databaseTableName: String { "files" }

    // MARK: - Auto-increment ID

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }

    // MARK: - Conversion to SearchResult

    func toSearchResult() -> SearchResult {
        SearchResult(
            id: UUID(),
            title: title,
            subtitle: subtitle,
            path: URL(fileURLWithPath: path),
            type: SearchResult.ResultType(rawValue: type) ?? .file,
            modifiedDate: modifiedDate,
            createdDate: createdDate,
            size: size,
            relevanceScore: isRecent ? 1.0 : 0.5
        )
    }

    // MARK: - Factory Methods

    static func from(url: URL, metadata: FileMetadata) -> IndexedFile {
        IndexedFile(
            id: nil,
            path: url.path,
            title: url.lastPathComponent,
            subtitle: url.deletingLastPathComponent().path,
            type: metadata.resultType.rawValue,
            size: metadata.size,
            modifiedDate: metadata.modifiedDate,
            createdDate: metadata.createdDate,
            contentHash: metadata.contentHash,
            isRecent: false,
            accessCount: 0,
            lastAccessed: nil
        )
    }
}

/// File metadata extracted during indexing.
struct FileMetadata {
    let size: Int64
    let modifiedDate: Date
    let createdDate: Date
    let contentHash: String?
    let resultType: SearchResult.ResultType
    let uti: String?
}
```

---

### 2. SearchStore.swift

**Location**: `Deep/Storage/SearchStore.swift`

```swift
import Foundation
import GRDB

/// Thread-safe SQLite database actor for search operations.
/// Uses GRDB.swift with FTS5 for full-text search.
actor SearchStore {

    // MARK: - Singleton

    static let shared = SearchStore()

    // MARK: - Properties

    private var dbPool: DatabasePool?
    private let dbPath: URL

    // MARK: - Initialization

    private init() {
        // Store in Application Support/Deep/
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        let deepDir = appSupport.appendingPathComponent("Deep", isDirectory: true)

        // Ensure directory exists
        try? FileManager.default.createDirectory(
            at: deepDir,
            withIntermediateDirectories: true
        )

        self.dbPath = deepDir.appendingPathComponent("search.db")
    }

    // MARK: - Database Lifecycle

    func open() async throws {
        var config = Configuration()
        config.prepareDatabase { db in
            db.trace { AppLogger.debug("SQL: \($0)", category: .indexing) }
        }

        dbPool = try DatabasePool(path: dbPath.path, configuration: config)
        try await migrate()
    }

    func close() {
        dbPool = nil
    }

    // MARK: - Migrations

    private func migrate() async throws {
        guard let dbPool else { return }

        var migrator = DatabaseMigrator()

        // Migration 1: Initial schema
        migrator.registerMigration("v1_initial") { db in
            // Files table
            try db.create(table: "files") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("path", .text).notNull().unique()
                t.column("title", .text).notNull()
                t.column("subtitle", .text).notNull()
                t.column("type", .text).notNull()
                t.column("size", .integer).notNull()
                t.column("modifiedDate", .datetime).notNull()
                t.column("createdDate", .datetime).notNull()
                t.column("contentHash", .text)
                t.column("isRecent", .boolean).notNull().defaults(to: false)
                t.column("accessCount", .integer).notNull().defaults(to: 0)
                t.column("lastAccessed", .datetime)
            }

            // FTS5 virtual table for full-text search
            try db.execute(sql: """
                CREATE VIRTUAL TABLE files_fts USING fts5(
                    title,
                    subtitle,
                    content,
                    path,
                    content='files',
                    content_rowid='id',
                    tokenize='porter unicode61'
                )
            """)

            // Triggers to keep FTS in sync
            try db.execute(sql: """
                CREATE TRIGGER files_ai AFTER INSERT ON files BEGIN
                    INSERT INTO files_fts(rowid, title, subtitle, content, path)
                    VALUES (new.id, new.title, new.subtitle, '', new.path);
                END
            """)

            try db.execute(sql: """
                CREATE TRIGGER files_ad AFTER DELETE ON files BEGIN
                    INSERT INTO files_fts(files_fts, rowid, title, subtitle, content, path)
                    VALUES ('delete', old.id, old.title, old.subtitle, '', old.path);
                END
            """)

            try db.execute(sql: """
                CREATE TRIGGER files_au AFTER UPDATE ON files BEGIN
                    INSERT INTO files_fts(files_fts, rowid, title, subtitle, content, path)
                    VALUES ('delete', old.id, old.title, old.subtitle, '', old.path);
                    INSERT INTO files_fts(rowid, title, subtitle, content, path)
                    VALUES (new.id, new.title, new.subtitle, '', new.path);
                END
            """)

            // Indexes for common queries
            try db.create(index: "idx_files_path", on: "files", columns: ["path"])
            try db.create(index: "idx_files_type", on: "files", columns: ["type"])
            try db.create(index: "idx_files_modified", on: "files", columns: ["modifiedDate"])
            try db.create(index: "idx_files_recent", on: "files", columns: ["isRecent", "lastAccessed"])
        }

        try await dbPool.write { db in
            try migrator.migrate(db)
        }
    }

    // MARK: - CRUD Operations

    func insertFile(_ file: IndexedFile) async throws {
        guard let dbPool else { throw SearchStoreError.notOpen }
        try await dbPool.write { db in
            try file.insert(db)
        }
    }

    func insertFiles(_ files: [IndexedFile]) async throws {
        guard let dbPool else { throw SearchStoreError.notOpen }
        try await dbPool.write { db in
            for file in files {
                try file.insert(db, onConflict: .replace)
            }
        }
    }

    func updateFile(_ file: IndexedFile) async throws {
        guard let dbPool else { throw SearchStoreError.notOpen }
        try await dbPool.write { db in
            try file.update(db)
        }
    }

    func deleteFile(path: String) async throws {
        guard let dbPool else { throw SearchStoreError.notOpen }
        try await dbPool.write { db in
            try db.execute(sql: "DELETE FROM files WHERE path = ?", arguments: [path])
        }
    }

    func deleteFilesInDirectory(_ directory: String) async throws {
        guard let dbPool else { throw SearchStoreError.notOpen }
        try await dbPool.write { db in
            try db.execute(
                sql: "DELETE FROM files WHERE path LIKE ?",
                arguments: [directory + "%"]
            )
        }
    }

    func fileExists(path: String) async throws -> Bool {
        guard let dbPool else { throw SearchStoreError.notOpen }
        return try await dbPool.read { db in
            try IndexedFile.filter(Column("path") == path).fetchCount(db) > 0
        }
    }

    func getFile(path: String) async throws -> IndexedFile? {
        guard let dbPool else { throw SearchStoreError.notOpen }
        return try await dbPool.read { db in
            try IndexedFile.filter(Column("path") == path).fetchOne(db)
        }
    }

    // MARK: - Content Operations

    func updateFileContent(fileId: Int64, content: String) async throws {
        guard let dbPool else { throw SearchStoreError.notOpen }
        try await dbPool.write { db in
            // Update FTS directly with content
            try db.execute(sql: """
                INSERT INTO files_fts(files_fts, rowid, title, subtitle, content, path)
                SELECT 'delete', id, title, subtitle, '', path FROM files WHERE id = ?
            """, arguments: [fileId])

            try db.execute(sql: """
                INSERT INTO files_fts(rowid, title, subtitle, content, path)
                SELECT id, title, subtitle, ?, path FROM files WHERE id = ?
            """, arguments: [content, fileId])
        }
    }

    // MARK: - Search

    func search(query: String, limit: Int = 50) async throws -> [IndexedFile] {
        guard let dbPool else { throw SearchStoreError.notOpen }

        let ftsQuery = query
            .split(separator: " ")
            .map { "\($0)*" }
            .joined(separator: " ")

        return try await dbPool.read { db in
            try IndexedFile.fetchAll(db, sql: """
                SELECT files.*
                FROM files
                JOIN files_fts ON files.id = files_fts.rowid
                WHERE files_fts MATCH ?
                ORDER BY
                    files.isRecent DESC,
                    bm25(files_fts, 10.0, 5.0, 1.0, 2.0) ASC,
                    files.modifiedDate DESC
                LIMIT ?
            """, arguments: [ftsQuery, limit])
        }
    }

    // MARK: - Recents

    func markAsRecent(path: String) async throws {
        guard let dbPool else { throw SearchStoreError.notOpen }
        try await dbPool.write { db in
            try db.execute(sql: """
                UPDATE files
                SET isRecent = 1,
                    accessCount = accessCount + 1,
                    lastAccessed = ?
                WHERE path = ?
            """, arguments: [Date(), path])
        }
    }

    func getRecents(limit: Int = 20) async throws -> [IndexedFile] {
        guard let dbPool else { throw SearchStoreError.notOpen }
        return try await dbPool.read { db in
            try IndexedFile
                .filter(Column("isRecent") == true)
                .order(Column("lastAccessed").desc)
                .limit(limit)
                .fetchAll(db)
        }
    }

    // MARK: - Statistics

    func getFileCount() async throws -> Int {
        guard let dbPool else { throw SearchStoreError.notOpen }
        return try await dbPool.read { db in
            try IndexedFile.fetchCount(db)
        }
    }

    func clearAll() async throws {
        guard let dbPool else { throw SearchStoreError.notOpen }
        try await dbPool.write { db in
            try db.execute(sql: "DELETE FROM files")
        }
    }
}

// MARK: - Errors

enum SearchStoreError: Error {
    case notOpen
    case migrationFailed(String)
    case insertFailed(String)
    case queryFailed(String)
}
```

---

### 3. ContentExtractor.swift

**Location**: `Deep/Indexing/Indexers/ContentExtractor.swift`

```swift
import Foundation

/// Extracts text content from files for full-text search indexing.
actor ContentExtractor {

    // MARK: - Configuration

    private let maxContentLength = 100_000  // 100KB of text content

    // MARK: - Public API

    func extractContent(from url: URL) async throws -> String? {
        let ext = url.pathExtension.lowercased()

        switch ext {
        // Plain text files
        case "txt", "md", "markdown", "rst", "csv":
            return try extractPlainText(from: url)

        // Source code files
        case "swift", "py", "js", "ts", "jsx", "tsx", "rb", "go", "rs",
             "java", "c", "cpp", "h", "hpp", "m", "mm", "cs", "php",
             "html", "css", "scss", "sass", "less", "json", "xml", "yaml", "yml",
             "sh", "bash", "zsh", "sql", "r", "scala", "kt", "lua", "pl",
             "toml", "ini", "conf", "cfg":
            return try extractPlainText(from: url)

        default:
            return nil
        }
    }

    // MARK: - Private Methods

    private func extractPlainText(from url: URL) throws -> String? {
        guard let handle = try? FileHandle(forReadingFrom: url) else {
            return nil
        }
        defer { try? handle.close() }

        let data = handle.readData(ofLength: maxContentLength)

        // Try UTF-8 first, then Latin-1
        if let content = String(data: data, encoding: .utf8) {
            return normalizeContent(content)
        } else if let content = String(data: data, encoding: .isoLatin1) {
            return normalizeContent(content)
        }

        return nil
    }

    private func normalizeContent(_ content: String) -> String {
        content
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
```

---

### 4. FileIndexer.swift

**Location**: `Deep/Indexing/Indexers/FileIndexer.swift`

```swift
import Foundation
import CryptoKit

/// Indexes user-selected folders with streaming traversal.
/// Extracts metadata and content for text files.
actor FileIndexer {

    // MARK: - Properties

    private let searchStore: SearchStore
    private let contentExtractor: ContentExtractor
    private let batchSize = 100

    private var isIndexing = false
    private var indexedCount = 0
    private var totalCount = 0

    // MARK: - Progress Reporting

    struct Progress {
        let indexed: Int
        let total: Int
        let currentPath: String?
        let isComplete: Bool

        var percentage: Double {
            guard total > 0 else { return 0 }
            return Double(indexed) / Double(total) * 100
        }
    }

    private var progressContinuation: AsyncStream<Progress>.Continuation?

    // MARK: - Initialization

    init(searchStore: SearchStore = .shared) {
        self.searchStore = searchStore
        self.contentExtractor = ContentExtractor()
    }

    // MARK: - Public API

    /// Index all enabled paths from IndexingStore.
    /// Returns an AsyncStream for progress updates.
    func indexAll(paths: [IndexedPath]) -> AsyncStream<Progress> {
        AsyncStream { continuation in
            self.progressContinuation = continuation

            Task {
                await self.performIndexing(paths: paths)
                continuation.finish()
            }
        }
    }

    /// Index a single directory.
    func indexDirectory(_ url: URL) async throws {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw FileIndexerError.directoryNotFound(url.path)
        }

        var batch: [IndexedFile] = []

        for await fileURL in streamDirectory(url) {
            do {
                let metadata = try extractMetadata(from: fileURL)
                var indexedFile = IndexedFile.from(url: fileURL, metadata: metadata)
                batch.append(indexedFile)

                // Batch insert for efficiency
                if batch.count >= batchSize {
                    try await searchStore.insertFiles(batch)

                    // Extract content for text/code files after insert
                    for file in batch {
                        if shouldExtractContent(for: metadata),
                           let fileId = file.id,
                           let content = try? await contentExtractor.extractContent(from: fileURL) {
                            try await searchStore.updateFileContent(fileId: fileId, content: content)
                        }
                    }

                    indexedCount += batch.count
                    batch.removeAll(keepingCapacity: true)
                    reportProgress(currentPath: fileURL.path)
                }
            } catch {
                AppLogger.warning("Failed to index \(fileURL.path): \(error)", category: .indexing)
            }
        }

        // Insert remaining batch
        if !batch.isEmpty {
            try await searchStore.insertFiles(batch)
            indexedCount += batch.count
        }
    }

    // MARK: - Private Methods

    private func performIndexing(paths: [IndexedPath]) async {
        isIndexing = true
        indexedCount = 0

        let enabledPaths = paths.filter { $0.isEnabled }

        // Count total files first (for progress)
        totalCount = await countFiles(in: enabledPaths.map { $0.url })

        AppLogger.info("Starting indexing of \(totalCount) files across \(enabledPaths.count) directories", category: .indexing)

        for path in enabledPaths {
            do {
                try await indexDirectory(path.url)
            } catch {
                AppLogger.error("Failed to index \(path.path): \(error)", category: .indexing)
            }
        }

        isIndexing = false
        reportProgress(currentPath: nil, isComplete: true)

        AppLogger.info("Indexing complete: \(indexedCount) files indexed", category: .indexing)
    }

    /// Stream directory contents without loading all into memory.
    private func streamDirectory(_ url: URL) -> AsyncStream<URL> {
        AsyncStream { continuation in
            Task {
                let fileManager = FileManager.default
                let resourceKeys: [URLResourceKey] = [
                    .isDirectoryKey,
                    .isRegularFileKey,
                    .isHiddenKey
                ]

                guard let enumerator = fileManager.enumerator(
                    at: url,
                    includingPropertiesForKeys: resourceKeys,
                    options: [.skipsHiddenFiles, .skipsPackageDescendants]
                ) else {
                    continuation.finish()
                    return
                }

                for case let fileURL as URL in enumerator {
                    if let values = try? fileURL.resourceValues(forKeys: Set(resourceKeys)),
                       values.isRegularFile == true,
                       values.isHidden != true {

                        if !shouldSkip(fileURL) {
                            continuation.yield(fileURL)
                        }
                    }
                }

                continuation.finish()
            }
        }
    }

    private func extractMetadata(from url: URL) throws -> FileMetadata {
        let resourceKeys: Set<URLResourceKey> = [
            .fileSizeKey,
            .contentModificationDateKey,
            .creationDateKey,
            .typeIdentifierKey
        ]

        let values = try url.resourceValues(forKeys: resourceKeys)

        let size = Int64(values.fileSize ?? 0)
        let modifiedDate = values.contentModificationDate ?? Date()
        let createdDate = values.creationDate ?? Date()
        let uti = values.typeIdentifier

        // Compute content hash for change detection (first 64KB)
        let contentHash = try computeHash(for: url)

        // Determine result type from UTI
        let resultType = determineResultType(from: uti, path: url.path)

        return FileMetadata(
            size: size,
            modifiedDate: modifiedDate,
            createdDate: createdDate,
            contentHash: contentHash,
            resultType: resultType,
            uti: uti
        )
    }

    private func computeHash(for url: URL) throws -> String? {
        guard let handle = try? FileHandle(forReadingFrom: url) else {
            return nil
        }
        defer { try? handle.close() }

        // Read first 64KB for hash
        let data = handle.readData(ofLength: 65536)
        guard !data.isEmpty else { return nil }

        let hash = SHA256.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }

    private func determineResultType(from uti: String?, path: String) -> SearchResult.ResultType {
        let ext = (path as NSString).pathExtension.lowercased()

        switch ext {
        case "swift", "py", "js", "ts", "rb", "go", "rs", "java", "c", "cpp", "h", "m", "mm":
            return .code
        case "pdf":
            return .pdf
        case "png", "jpg", "jpeg", "gif", "heic", "webp", "svg", "tiff":
            return .image
        case "app":
            return .application
        case "md", "txt", "rtf", "doc", "docx", "pages":
            return .document
        default:
            break
        }

        if let uti = uti {
            if uti.contains("folder") || uti.contains("directory") {
                return .folder
            }
            if uti.contains("source-code") || uti.contains("script") {
                return .code
            }
            if uti.contains("image") {
                return .image
            }
            if uti.contains("pdf") {
                return .pdf
            }
        }

        return .file
    }

    private func shouldSkip(_ url: URL) -> Bool {
        let path = url.path

        let skipPatterns = [
            ".git/",
            ".svn/",
            "node_modules/",
            ".build/",
            "DerivedData/",
            ".Trash/",
            "__pycache__/",
            ".cache/",
            "Pods/"
        ]

        for pattern in skipPatterns {
            if path.contains(pattern) {
                return true
            }
        }

        return false
    }

    private func shouldExtractContent(for metadata: FileMetadata) -> Bool {
        guard metadata.size < 1_000_000 else { return false }

        switch metadata.resultType {
        case .code, .document:
            return true
        default:
            return false
        }
    }

    private func countFiles(in urls: [URL]) async -> Int {
        var count = 0
        let fileManager = FileManager.default

        for url in urls {
            guard let enumerator = fileManager.enumerator(
                at: url,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else { continue }

            for case let fileURL as URL in enumerator {
                if let values = try? fileURL.resourceValues(forKeys: [.isRegularFileKey]),
                   values.isRegularFile == true,
                   !shouldSkip(fileURL) {
                    count += 1
                }
            }
        }

        return count
    }

    private func reportProgress(currentPath: String?, isComplete: Bool = false) {
        progressContinuation?.yield(Progress(
            indexed: indexedCount,
            total: totalCount,
            currentPath: currentPath,
            isComplete: isComplete
        ))
    }
}

// MARK: - Errors

enum FileIndexerError: Error {
    case directoryNotFound(String)
    case accessDenied(String)
    case metadataExtractionFailed(String)
}
```

---

### 5. AppsIndexer.swift

**Location**: `Deep/Indexing/Indexers/AppsIndexer.swift`

```swift
import Foundation

/// Indexes applications from /Applications and ~/Applications.
actor AppsIndexer {

    // MARK: - Properties

    private let searchStore: SearchStore

    // MARK: - Initialization

    init(searchStore: SearchStore = .shared) {
        self.searchStore = searchStore
    }

    // MARK: - Public API

    func indexApplications() async throws {
        let applicationDirs = [
            URL(fileURLWithPath: "/Applications"),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications")
        ]

        var apps: [IndexedFile] = []

        for dir in applicationDirs {
            guard FileManager.default.fileExists(atPath: dir.path) else { continue }

            let contents = try FileManager.default.contentsOfDirectory(
                at: dir,
                includingPropertiesForKeys: [.isApplicationKey, .contentModificationDateKey, .creationDateKey],
                options: [.skipsHiddenFiles]
            )

            for url in contents where url.pathExtension == "app" {
                if let app = try? createIndexedApp(from: url) {
                    apps.append(app)
                }
            }
        }

        try await searchStore.insertFiles(apps)
        AppLogger.info("Indexed \(apps.count) applications", category: .indexing)
    }

    // MARK: - Private Methods

    private func createIndexedApp(from url: URL) throws -> IndexedFile {
        let resourceKeys: Set<URLResourceKey> = [
            .contentModificationDateKey,
            .creationDateKey,
            .fileSizeKey
        ]

        let values = try url.resourceValues(forKeys: resourceKeys)
        let name = url.deletingPathExtension().lastPathComponent

        return IndexedFile(
            id: nil,
            path: url.path,
            title: name,
            subtitle: "Applications",
            type: SearchResult.ResultType.application.rawValue,
            size: Int64(values.fileSize ?? 0),
            modifiedDate: values.contentModificationDate ?? Date(),
            createdDate: values.creationDate ?? Date(),
            contentHash: nil,
            isRecent: false,
            accessCount: 0,
            lastAccessed: nil
        )
    }
}
```

---

### 6. RecentsTracker.swift

**Location**: `Deep/Indexing/Tracking/RecentsTracker.swift`

```swift
import Foundation
import AppKit

/// Tracks recently opened files from both system and Deep app.
actor RecentsTracker {

    // MARK: - Properties

    private let searchStore: SearchStore
    private var lastSystemRecentsUpdate: Date?

    // MARK: - Initialization

    init(searchStore: SearchStore = .shared) {
        self.searchStore = searchStore
    }

    // MARK: - Public API

    /// Sync system recent documents to the search store.
    func syncSystemRecents() async throws {
        let recentURLs = await MainActor.run {
            NSDocumentController.shared.recentDocumentURLs
        }

        for url in recentURLs {
            do {
                try await markAsRecent(url: url)
            } catch {
                AppLogger.warning("Failed to mark recent: \(url.path) - \(error)", category: .indexing)
            }
        }

        lastSystemRecentsUpdate = Date()
        AppLogger.info("Synced \(recentURLs.count) system recents", category: .indexing)
    }

    /// Mark a file as recently accessed (called when user opens via Deep).
    func markAsRecentFromApp(url: URL) async throws {
        try await markAsRecent(url: url)
        AppLogger.info("Marked as recent (from Deep): \(url.lastPathComponent)", category: .indexing)
    }

    /// Get recent files for display.
    func getRecents(limit: Int = 20) async throws -> [SearchResult] {
        let recents = try await searchStore.getRecents(limit: limit)
        return recents.map { $0.toSearchResult() }
    }

    // MARK: - Private Methods

    private func markAsRecent(url: URL) async throws {
        let exists = try await searchStore.fileExists(path: url.path)

        if exists {
            try await searchStore.markAsRecent(path: url.path)
        } else {
            let metadata = try extractMetadata(from: url)
            var indexedFile = IndexedFile.from(url: url, metadata: metadata)
            indexedFile.isRecent = true
            indexedFile.lastAccessed = Date()
            indexedFile.accessCount = 1
            try await searchStore.insertFile(indexedFile)
        }
    }

    private func extractMetadata(from url: URL) throws -> FileMetadata {
        let resourceKeys: Set<URLResourceKey> = [
            .fileSizeKey,
            .contentModificationDateKey,
            .creationDateKey,
            .typeIdentifierKey
        ]

        let values = try url.resourceValues(forKeys: resourceKeys)

        return FileMetadata(
            size: Int64(values.fileSize ?? 0),
            modifiedDate: values.contentModificationDate ?? Date(),
            createdDate: values.creationDate ?? Date(),
            contentHash: nil,
            resultType: determineType(from: url),
            uti: values.typeIdentifier
        )
    }

    private func determineType(from url: URL) -> SearchResult.ResultType {
        let ext = url.pathExtension.lowercased()

        switch ext {
        case "swift", "py", "js", "ts", "rb", "go", "rs", "java", "c", "cpp", "h", "m":
            return .code
        case "pdf":
            return .pdf
        case "png", "jpg", "jpeg", "gif", "heic", "webp":
            return .image
        case "app":
            return .application
        case "md", "txt", "rtf", "doc", "docx":
            return .document
        default:
            return url.hasDirectoryPath ? .folder : .file
        }
    }
}
```

---

### 7. IndexingCoordinator.swift

**Location**: `Deep/Indexing/Coordinator/IndexingCoordinator.swift`

```swift
import Foundation
import Observation

/// Orchestrates all indexing operations and reports overall progress.
@Observable
@MainActor
final class IndexingCoordinator {

    // MARK: - Singleton

    static let shared = IndexingCoordinator()

    // MARK: - State

    enum State: Equatable {
        case idle
        case indexing(phase: Phase, progress: Double)
        case complete(fileCount: Int)
        case error(String)

        enum Phase: String {
            case applications = "Indexing applications..."
            case files = "Indexing files..."
            case recents = "Syncing recent files..."
        }
    }

    var state: State = .idle

    // MARK: - Components

    private let searchStore: SearchStore
    private let fileIndexer: FileIndexer
    private let appsIndexer: AppsIndexer
    private let recentsTracker: RecentsTracker

    private var indexingTask: Task<Void, Never>?

    // MARK: - Initialization

    private init() {
        self.searchStore = .shared
        self.fileIndexer = FileIndexer()
        self.appsIndexer = AppsIndexer()
        self.recentsTracker = RecentsTracker()
    }

    // MARK: - Public API

    /// Start full indexing on app launch.
    func startIndexing() {
        guard case .idle = state else {
            AppLogger.warning("Indexing already in progress", category: .indexing)
            return
        }

        indexingTask = Task { [weak self] in
            await self?.performFullIndexing()
        }
    }

    /// Cancel ongoing indexing.
    func cancelIndexing() {
        indexingTask?.cancel()
        indexingTask = nil
        state = .idle
        AppLogger.info("Indexing cancelled", category: .indexing)
    }

    /// Re-index when user adds/removes folders.
    func reindexUserFolders() {
        indexingTask?.cancel()

        indexingTask = Task { [weak self] in
            await self?.indexUserFolders()
        }
    }

    /// Mark file as recently accessed (call when user opens file via Deep).
    func markFileAsRecent(url: URL) {
        Task {
            try? await recentsTracker.markAsRecentFromApp(url: url)
        }
    }

    // MARK: - Private Methods

    private func performFullIndexing() async {
        AppLogger.info("Starting full indexing", category: .indexing)

        do {
            // Open database
            try await searchStore.open()

            // Phase 1: Index applications
            state = .indexing(phase: .applications, progress: 0)
            try await appsIndexer.indexApplications()

            // Phase 2: Index user folders
            await indexUserFolders()

            // Phase 3: Sync system recents
            state = .indexing(phase: .recents, progress: 90)
            try await recentsTracker.syncSystemRecents()

            // Complete
            let count = try await searchStore.getFileCount()
            state = .complete(fileCount: count)
            AppLogger.info("Full indexing complete: \(count) files", category: .indexing)

        } catch {
            state = .error(error.localizedDescription)
            AppLogger.error("Indexing failed: \(error)", category: .indexing)
        }
    }

    private func indexUserFolders() async {
        state = .indexing(phase: .files, progress: 10)

        let paths = IndexingStore.shared.paths

        guard !paths.isEmpty else {
            AppLogger.info("No user folders configured for indexing", category: .indexing)
            return
        }

        for await progress in await fileIndexer.indexAll(paths: paths) {
            let overallProgress = 10 + (progress.percentage * 0.8)
            state = .indexing(phase: .files, progress: overallProgress)

            if progress.isComplete {
                break
            }
        }
    }
}
```

---

### 8. FileSearchProvider.swift

**Location**: `Deep/Search/Services/Providers/FileSearchProvider.swift`

```swift
import Foundation

/// Real search provider using SQLite FTS5.
final class FileSearchProvider: SearchProviding {

    // MARK: - Properties

    let name = "Files"
    private let searchStore: SearchStore
    private var currentTask: Task<[SearchResult], Error>?

    // MARK: - Initialization

    init(searchStore: SearchStore = .shared) {
        self.searchStore = searchStore
    }

    // MARK: - SearchProviding

    func search(query: String) async throws -> [SearchResult] {
        currentTask?.cancel()

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return []
        }

        currentTask = Task {
            let indexedFiles = try await searchStore.search(query: trimmed, limit: 50)
            return indexedFiles.map { $0.toSearchResult() }
        }

        return try await currentTask!.value
    }

    func cancelSearch() {
        currentTask?.cancel()
        currentTask = nil
    }
}
```

---

## Files to Modify

### 9. AppDelegate.swift

Add to `applicationDidFinishLaunching`:

```swift
func applicationDidFinishLaunching(_ notification: Notification) {
    AppLogger.info("Application did finish launching", category: .app)
    setupPanel()
    setupHotKey()

    // Start background indexing
    startBackgroundIndexing()
}

private func startBackgroundIndexing() {
    Task { @MainActor in
        IndexingCoordinator.shared.startIndexing()
    }
}
```

---

### 10. DeepSearchView+ViewModel.swift

Change the default provider:

```swift
init(searchProvider: SearchProviding = FileSearchProvider()) {
    self.searchProvider = searchProvider
}
```

Add recent tracking when opening files (if you have an `openFile` method):

```swift
private func openFile(_ result: SearchResult) {
    NSWorkspace.shared.open(result.path)
    IndexingCoordinator.shared.markFileAsRecent(url: result.path)
}
```

---

## Data Flow

### Indexing (On App Launch)
```
AppDelegate.applicationDidFinishLaunching()
  └─> IndexingCoordinator.shared.startIndexing()
      └─> SearchStore.open()
      └─> AppsIndexer.indexApplications()
      └─> FileIndexer.indexAll(IndexingStore.shared.paths)
          └─> streamDirectory() [AsyncStream]
          └─> extractMetadata() + ContentExtractor
          └─> SearchStore.insertFiles() [batch 100]
      └─> RecentsTracker.syncSystemRecents()
```

### Search (On User Query)
```
ViewModel.query didSet
  └─> performSearch()
      └─> FileSearchProvider.search(query)
          └─> SearchStore.search(query, limit: 50)
              └─> FTS5 MATCH + BM25 ranking
          └─> IndexedFile.toSearchResult()
      └─> ViewModel.results = [SearchResult]
```

---

## Verification Checklist

1. **Add GRDB**: Build succeeds after adding package
2. **Schema**: DB file created at `~/Library/Application Support/Deep/search.db`
3. **Indexing**: Add folder in Settings, restart app, check logs for "Indexing complete"
4. **Search**: Type filename → results appear from indexed folders
5. **Apps**: Type "Xcode" → finds `/Applications/Xcode.app`
6. **Recents**: Open file via Deep → appears with recency boost on next search
7. **Content**: Search for text inside a `.swift` file → finds it

---

## Performance Targets

| Metric | Target |
|--------|--------|
| Index 100K files | < 2 minutes |
| Search latency | < 50ms |
| Incremental update | < 1 second |
| Memory usage | < 200MB |
