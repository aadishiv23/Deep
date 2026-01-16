# Deep - Development Phases

High-level roadmap for building Deep into a unified search layer for macOS.

## Phase 0: Foundation ✅ COMPLETE

**Goal**: Basic Spotlight-style interface with global activation

**Deliverables**:
- Global hotkey (Cmd+Shift+Space) registration via Carbon
- Floating borderless panel with custom `SpotlightPanel` subclass
- Double-escape dismissal
- MenuBarExtra for menu actions (no ghost windows)
- `@Observable` AppState with mode switching (setup/main/debug)
- Logging system with categories

**Status**: Complete

---

## Phase 1: Setup + Debug Views ✅ COMPLETE

**Goal**: First-run experience and developer tooling

**Deliverables**:
- SetupView with onboarding flow
- DebugView showing app state and diagnostics
- RootView switches between modes based on AppState
- State persistence with UserDefaults

**Status**: Complete

---

## Phase 2: Preferences Window 🔄 IN PROGRESS

**Goal**: User-configurable settings without editing code

**Deliverables**:
- Settings window via SwiftUI `Settings` scene
- General settings: launch at login, menu bar icon visibility
- Hotkey display (read-only for now)
- **Indexing settings**: folder selection with NSOpenPanel
- `IndexingStore` singleton managing list of paths to index
- `IndexedPath` model (Codable, persisted via UserDefaults)
- Developer settings: show/hide debug tools

**What's Done**:
- ✅ Settings window UI structure
- ✅ SettingsKeys constants
- ✅ SettingsLink in MenuBarExtra (Cmd+,)
- ✅ IndexedPath model
- ✅ IndexingStore with persistence
- ✅ Folder picker UI

**What's Left**:
- ⏳ Wire up "Launch at Login" with SMAppService
- ⏳ Wire up "Show Menu Bar Icon" (or remove setting)
- ⏳ Wire up "Show Debug Tools" to hide menu items
- ⏳ UI polish (width, constraints, help text)

---

## Phase 3: UI Polish ✅ COMPLETE

**Goal**: Make the panel look and feel like Spotlight

**Deliverables**:
- ✅ Blur/vibrancy background with `.regularMaterial`
- ✅ Rounded corners (25pt radius) and proper shadows
- ✅ Search field auto-focuses on show
- ✅ Search results list with keyboard navigation (↑↓, Enter, Space, Cmd+R)
- ✅ Smooth show/hide animations
- ✅ Proper spacing, typography, and visual hierarchy
- ✅ Inset/framed layout (12pt horizontal padding)
- ✅ Split-view detail panel (conditional display based on result type)
- ✅ Fixed panel size: 750x560
- ✅ Fixed animations and flicker issues

**What's Done**:
- Keyboard navigation with selection highlighting
- Quick Look preview (spacebar) - stubbed with logging
- Reveal in Finder (Cmd+R) - stubbed with logging
- Detail panel shows metadata: Modified, Created, Size, Kind
- Detail panel shows actions: Open, Quick Look, Reveal in Finder
- Results list stays fixed width (375px) when detail panel slides in
- No flicker on empty results or during search
- Single tap selects, double tap opens file

**Status**: Complete. Ready for Phase 5 (real file indexing)

---

## Phase 4: Search Architecture Foundation ✅ COMPLETE

**Goal**: Clean, testable search pipeline before real indexing

**Deliverables**:
- ✅ Domain / Data / Presentation layer separation
- ✅ `SearchResult` model with metadata (title, subtitle, path, type, dates, size, relevance)
- ✅ `SearchProvider` protocol with async search and cancellation
- ✅ `StubSearchProvider` with realistic mock data
- ✅ ViewModel with async search, task cancellation, and debouncing
- ✅ Real data flowing through UI (no more mock strings)

**Architecture**:
```
UI Layer:        DeepSearchView → ViewModel
Data Layer:      ViewModel → SearchProvider → [SearchResult]
```

**What's Done**:
- `SearchResult` with `ResultType` enum (file, folder, application, document, code, image, pdf)
- `SearchProvider` protocol with `search(query:)` async throws
- `StubSearchProvider` filtering mock results by query
- ViewModel triggers search on query change via `didSet`
- Async/await search with proper cancellation
- `isSearching` state to prevent flicker
- Helper methods for formatting (dates, file sizes)

**Status**: Complete. Ready to swap `StubSearchProvider` for `FileSearchProvider` in Phase 5

**Why This Matters**:
- Search is async, cancellable, and non-blocking
- Multiple providers (files, apps, contacts) can share the same interface
- Testable with mocks before dealing with real file system
- UI completely decoupled from data source

---

## Phase 5: File Indexing + Search

**Goal**: Fast, reliable file indexing at scale

**Sub-phases** (in order):

### 5.1: SQLite Foundation
- `SearchStore` actor with thread-safe access
- Schema design: files, metadata, FTS5 for full-text search
- Migration system for schema updates
- Basic CRUD operations

### 5.2: File Indexer
- `FileIndexer` actor with streaming directory traversal
- Metadata extraction (name, path, size, dates, UTI)
- Content extraction for text files
- Hash-based change detection (skip unchanged files)
- Progress reporting

### 5.3: File Watcher
- `FileWatcher` with FSEvents integration
- Incremental reindexing on file changes
- Debouncing for rapid changes
- Handle renames, moves, deletes

### 5.4: Search Implementation
- `FileSearchProvider` querying SQLite store
- Ranking algorithm (recency, frequency, fuzzy match)
- Result pagination and limits
- Performance tuning (indexes, query optimization)

### 5.5: Optimization
- Parallel indexing for multiple directories
- Background queue for non-blocking updates
- Memory-efficient batch processing
- Benchmark and optimize hot paths

**Data Flow**:
```
IndexingStore.paths → FileIndexer → SearchStore (SQLite)
User Query → FileSearchProvider → SearchStore → Results
FSEvents → FileWatcher → FileIndexer → SearchStore
```

---

## Phase 6: Additional Providers (Optional)

**Goal**: Expand search beyond files

**Potential Providers**:
- Applications (`.app` bundles)
- System Preferences
- Contacts (with permission)
- Calendar events (with permission)
- Notes (with permission)
- Messages (with permission)
- Browser bookmarks
- Recently opened documents

**Each Provider**:
- Implements `SearchProvider` protocol
- Requests permissions if needed
- Updates incrementally
- Respects user privacy settings

---

## Phase 7: Intelligence + Ranking

**Goal**: Smarter results based on usage patterns

**Features**:
- Click tracking (which results user selects)
- Recency boost (recently accessed files rank higher)
- Frequency boost (often-opened files rank higher)
- Context awareness (current app, time of day)
- Query spelling correction
- Synonyms and aliases
- Natural language parsing ("open my presentation from last week")

---

## Phase 8: Advanced Features

**Goal**: Power user features and polish

**Features**:
- Actions on results (Quick Look, Open With, Move to Trash)
- Plugins/extensions API
- Custom hotkey configuration
- Search filters (type:pdf, modified:today)
- Search scopes (limit to specific folders)
- Cloud storage integration (Dropbox, Google Drive)
- Network drive indexing
- Exclude patterns (.git, node_modules)

---

## Open Questions

- **macOS Version**: Target macOS 14+ only, or support macOS 13?
- **Background Process**: Menu bar app only, or launch agent for always-on indexing?
- **First Release Scope**: What's MVP for v0.1 vs v0.2?
- **Privacy**: How to handle sensitive folders (~/Library, etc.)?
- **Performance**: What's acceptable initial index time for 1TB of files?

---

## Success Metrics

**Phase 2-3 (UI + Settings)**:
- Settings persist correctly
- UI feels fast and responsive
- No visual glitches or layout issues

**Phase 5 (Indexing)**:
- Index 100K files in < 2 minutes
- Search returns results in < 50ms
- Incremental updates within 1 second of file change
- Memory usage < 200MB for typical workload

**Phase 7+ (Intelligence)**:
- Top result is correct 80%+ of the time
- Users find what they need in < 3 keystrokes average
