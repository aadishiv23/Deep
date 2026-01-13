# Data Models

## SearchResult

The core model representing a single search result item.

### Structure

```swift
// Deep/Models/SearchResult.swift
struct SearchResult: Identifiable, Hashable {
    let id: UUID
    let title: String           // "ContentView.swift"
    let subtitle: String        // "Deep/Deep" (folder path)
    let path: URL               // Full file path
    let type: ResultType
    let modifiedDate: Date      // For recency sorting (Phase 7)
    let relevanceScore: Double  // For ranking (Phase 7)

    enum ResultType {
        case file
        case folder
        case application
        case document
        case code
        case image
        case pdf

        var icon: String {
            switch self {
            case .file: return "doc.fill"
            case .folder: return "folder.fill"
            case .application: return "app.fill"
            case .document: return "doc.text.fill"
            case .code: return "chevron.left.forwardslash.chevron.right"
            case .image: return "photo.fill"
            case .pdf: return "doc.richtext.fill"
            }
        }

        var color: Color {
            switch self {
            case .file: return .gray
            case .folder: return .blue
            case .application: return .purple
            case .document: return .orange
            case .code: return .green
            case .image: return .pink
            case .pdf: return .red
            }
        }
    }
}

// MARK: - Mock Data (Phase 3)
extension SearchResult {
    static let mockResults: [SearchResult] = [
        SearchResult(
            id: UUID(),
            title: "ContentView.swift",
            subtitle: "Deep/Deep",
            path: URL(fileURLWithPath: "/Users/.../Deep/ContentView.swift"),
            type: .code,
            modifiedDate: Date(),
            relevanceScore: 1.0
        ),
        SearchResult(
            id: UUID(),
            title: "AppDelegate.swift",
            subtitle: "Deep/Deep",
            path: URL(fileURLWithPath: "/Users/.../Deep/AppDelegate.swift"),
            type: .code,
            modifiedDate: Date(),
            relevanceScore: 0.95
        ),
        SearchResult(
            id: UUID(),
            title: "Deep.xcodeproj",
            subtitle: "Desktop/SwiftProjects/Deep",
            path: URL(fileURLWithPath: "/Users/.../Deep.xcodeproj"),
            type: .folder,
            modifiedDate: Date(),
            relevanceScore: 0.9
        ),
        SearchResult(
            id: UUID(),
            title: "Design_Assets.figma",
            subtitle: "Documents/Projects",
            path: URL(fileURLWithPath: "/Users/.../Design_Assets.figma"),
            type: .file,
            modifiedDate: Date(),
            relevanceScore: 0.85
        ),
        SearchResult(
            id: UUID(),
            title: "Meeting_Notes.pdf",
            subtitle: "Documents",
            path: URL(fileURLWithPath: "/Users/.../Meeting_Notes.pdf"),
            type: .pdf,
            modifiedDate: Date(),
            relevanceScore: 0.8
        ),
        SearchResult(
            id: UUID(),
            title: "Xcode.app",
            subtitle: "Applications",
            path: URL(fileURLWithPath: "/Applications/Xcode.app"),
            type: .application,
            modifiedDate: Date(),
            relevanceScore: 0.75
        ),
        SearchResult(
            id: UUID(),
            title: "Screenshot.png",
            subtitle: "Desktop",
            path: URL(fileURLWithPath: "/Users/.../Screenshot.png"),
            type: .image,
            modifiedDate: Date(),
            relevanceScore: 0.7
        ),
        SearchResult(
            id: UUID(),
            title: "Notes.md",
            subtitle: "Documents",
            path: URL(fileURLWithPath: "/Users/.../Notes.md"),
            type: .document,
            modifiedDate: Date(),
            relevanceScore: 0.65
        )
    ]
}
```

### Design Decisions

**Why Identifiable?**
- Required for SwiftUI `ForEach`
- UUID ensures uniqueness across all results

**Why Hashable?**
- Enables selection tracking
- Required for efficient Set operations

**Why URL instead of String for path?**
- Type-safe file path handling
- Easier to open files with `NSWorkspace.shared.open(url)`
- Built-in path manipulation methods

**Why ResultType enum?**
- Type-safe categorization
- Easy icon/color mapping
- Extensible for future types

**Why relevanceScore?**
- Phase 7: Ranking algorithm will use this
- Allows sorting by relevance + recency + frequency
- Default 1.0 for exact matches, < 1.0 for fuzzy matches

**Why modifiedDate?**
- Phase 7: Recency boost in ranking
- "Recently modified" filter
- Sorting by last modified

---

## IndexedPath

Model for folders to index (already implemented).

```swift
// Deep/Models/IndexedPath.swift
struct IndexedPath: Identifiable, Codable {
    let id: UUID
    let path: String
    var isEnabled: Bool

    var displayName: String {
        URL(fileURLWithPath: path).lastPathComponent
    }
}
```

**Purpose**: Stores which folders the user wants indexed for search.

**Persistence**: Saved to UserDefaults via `IndexingStore.shared`

---

## Future Models (Phase 4+)

### SearchQuery
```swift
struct SearchQuery {
    let text: String
    let filters: [SearchFilter]
    let scope: SearchScope?
}

enum SearchFilter {
    case type(ResultType)
    case modifiedAfter(Date)
    case modifiedBefore(Date)
    case size(min: Int64?, max: Int64?)
}

enum SearchScope {
    case everywhere
    case folder(URL)
    case application
}
```

### UnifiedSearchResult
```swift
struct UnifiedSearchResult {
    let results: [SearchResult]
    let query: SearchQuery
    let totalCount: Int
    let executionTime: TimeInterval
}
```
