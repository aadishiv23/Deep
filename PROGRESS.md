# Deep - Progress Report

**Last Updated**: January 13, 2026

---

## 🎯 Current Status

Deep is a **functional Spotlight-style search interface** with:
- Polished UI with keyboard navigation
- Split-view detail panel
- Clean architecture ready for real file indexing
- Mock data provider for testing

**Ready for**: Phase 5 (File Indexing with SQLite)

---

## ✅ Completed Phases

### Phase 0: Foundation ✅
- Global hotkey (Cmd+Shift+Space) via Carbon API
- Floating borderless panel (`SpotlightPanel` subclass)
- Double-escape dismissal
- MenuBarExtra (no ghost windows)
- `@Observable` AppState with mode switching
- Logging system with categories

### Phase 1: Setup + Debug Views ✅
- SetupView with onboarding flow
- DebugView showing app state and diagnostics
- RootView switches modes based on AppState
- State persistence with UserDefaults

### Phase 3: UI Polish ✅
**Panel Design:**
- Size: 750x560 pixels
- Rounded corners: 25pt radius
- `.regularMaterial` background blur
- Inset layout with 12pt padding (Maps-style framing)
- Search bar: 675px min width

**Keyboard Navigation:**
- ↑↓ arrows: Navigate results
- Enter: Open file and dismiss
- Space: Quick Look preview (stubbed)
- Cmd+R: Reveal in Finder (stubbed)
- Escape: Dismiss panel (double-tap)

**Split-View Layout:**
- Left: Results list (375px width)
- Right: Detail panel (375px width, conditional)
- Detail panel shows: title, path, metadata, actions
- Detail only appears for files/folders/documents (not apps)
- Smooth slide-in animation from right

**Visual Polish:**
- Selection highlighting with `.accentColor` opacity
- Single tap selects result
- Double tap opens file
- Auto-scroll to selected item
- No flicker on search or empty results
- Smooth transitions and animations

### Phase 4: Search Architecture ✅
**Models:**
- `SearchResult`: id, title, subtitle, path, type, modifiedDate, createdDate, size, relevanceScore
- `ResultType` enum: file, folder, application, document, code, image, pdf
- Helper methods: `formattedSize`, `formattedModifiedDate`, `formattedCreatedDate`

**Architecture:**
- `SearchProvider` protocol with async search
- `StubSearchProvider` with 8 realistic mock results
- ViewModel with async search, task cancellation
- Search triggered on query change via `didSet`
- `isSearching` state for loading UI

**Data Flow:**
```
User types → ViewModel.query (didSet) → performSearch()
  → StubSearchProvider.search(query:) → filter mockResults
  → ViewModel.results → UI updates
```

---

## 🔄 In Progress

### Phase 2: Preferences Window
**What's Done:**
- Settings window with 3 tabs (General/Indexing/Developer)
- IndexingStore for folder paths persistence
- Folder picker with NSOpenPanel
- SettingsKeys constants
- UI structure complete

**What's Left:**
- Wire up "Launch at Login" with SMAppService
- Wire up "Show Debug Tools" to conditionally hide menu items
- Decide on "Show Menu Bar Icon" approach (or remove)

---

## ⏳ Next Up: Phase 5 - File Indexing

### 5.1: SQLite Foundation
**Goal**: Database for file metadata and full-text search

**Tasks:**
- Create `SearchStore` actor with thread-safe SQLite access
- Design schema:
  - `files` table: id, path, title, size, modified_date, created_date, type
  - FTS5 virtual table for full-text content search
- Migration system for schema updates
- Basic CRUD: insert, update, delete, query

### 5.2: File Indexer
**Goal**: Traverse directories and extract metadata

**Tasks:**
- Create `FileIndexer` actor
- Read folders from `IndexingStore.shared.paths`
- Streaming directory traversal (don't load all files in memory)
- Extract metadata: name, path, size, dates, UTI
- Extract content for text files (for FTS5)
- Hash-based change detection (skip unchanged files)
- Progress reporting for UI

### 5.3: File Search Provider
**Goal**: Replace stub with real file search

**Tasks:**
- Create `FileSearchProvider` implementing `SearchProvider`
- Query SQLite with FTS5 for text matching
- Ranking algorithm (combine relevance score + recency + frequency)
- Return `[SearchResult]` from database
- Swap `StubSearchProvider` for `FileSearchProvider` in ViewModel

### 5.4: File Watcher (Later)
**Goal**: Keep index up-to-date automatically

**Tasks:**
- FSEvents integration for file system changes
- Incremental reindexing on file add/modify/delete
- Debouncing for rapid changes
- Handle renames, moves, deletes correctly

---

## 📊 Project Structure

```
Deep/
├── DeepApp.swift              # @main, MenuBarExtra
├── AppDelegate.swift          # Panel lifecycle, hotkey
├── AppState.swift             # @Observable app state
├── RootView.swift             # Mode switching, double-escape
├── SpotlightPanel.swift       # Custom NSPanel
├── SetupView.swift            # First-run onboarding
├── DebugView.swift            # Developer diagnostics
├── Settings/
│   └── SettingsView.swift     # Preferences window
├── Search/
│   ├── DeepSearchView.swift            # Main search UI
│   ├── DeepSearchView+ViewModel.swift  # Search state management
│   ├── Models/
│   │   └── SearchResult.swift          # Result data model
│   └── Services/
│       ├── SearchProvider.swift        # Protocol
│       └── StubSearchProvider.swift    # Mock implementation
├── Models/
│   └── IndexedPath.swift      # Folder to index
├── Stores/
│   └── IndexingStore.swift    # Path persistence
└── Utilities/
    ├── Logger.swift           # Logging with categories
    ├── SettingsKeys.swift     # @AppStorage constants
    └── DesignSystem.swift     # UI constants
```

---

## 🎨 UI/UX Highlights

### What Works Well
- **Instant search**: Results appear as you type (async with 50ms mock delay)
- **Keyboard-first**: Full navigation without touching mouse
- **Adaptive layout**: Detail panel only shows when useful
- **Smooth animations**: No jank, no flicker
- **Clean design**: Matches macOS Spotlight aesthetics

### Known Limitations
- Mock data only (no real file search yet)
- Quick Look and Reveal in Finder are stubbed (log only)
- No file thumbnails or previews
- No search history or recent items
- Settings toggles don't actually work yet

---

## 🚀 Success Metrics

**Phase 3 Targets**: ✅ Met
- UI feels fast and responsive
- No visual glitches or layout issues
- Keyboard navigation works perfectly

**Phase 5 Targets**: TBD
- Index 100K files in < 2 minutes
- Search returns results in < 50ms
- Incremental updates within 1 second of file change
- Memory usage < 200MB for typical workload

---

## 📝 Technical Decisions

### Why StubSearchProvider First?
Building the UI with mock data lets us:
1. Perfect the UX before dealing with SQLite complexity
2. Test animations and interactions
3. Validate the architecture works
4. Swap providers easily when ready

### Why Split-View?
Provides:
1. Quick metadata overview without opening files
2. Context for which file is selected
3. Action shortcuts visible at all time
4. Raycast-like professional feel

### Why Conditional Detail?
Applications don't need detail panels - everyone knows what Xcode is. Files/documents benefit from showing path, size, dates. Adaptive UI = better UX.

### Why No Loading Spinners?
Search is so fast (50ms mock, likely <100ms with SQLite) that showing loading states causes more flicker than just waiting. Keep it simple.

---

## 🎯 Next Session Goals

1. **Finish Phase 2 Settings** (30 min)
   - Launch at Login wiring
   - Show Debug Tools conditional display

2. **Start Phase 5.1: SQLite** (2-3 hours)
   - Set up SQLite.swift dependency
   - Create SearchStore actor
   - Design and test schema
   - Basic insert/query operations

3. **Phase 5.2: File Indexer** (2-3 hours)
   - FileIndexer actor
   - Directory traversal
   - Metadata extraction
   - Initial indexing from IndexingStore paths

Once Phase 5.1-5.3 are done, Deep becomes a **fully functional Spotlight replacement** with real file search!
