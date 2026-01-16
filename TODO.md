# TODO

## Current Status (Jan 13, 2026)

**Completed Phases:**
- ✅ Phase 0: Foundation
- ✅ Phase 1: Setup + Debug Views
- ✅ Phase 3: UI Polish
- ✅ Phase 4: Search Architecture

**In Progress:**
- 🔄 Phase 2: Preferences (settings wiring remaining)

**Next Up:**
- ⏳ Phase 5: File Indexing

---

## Phase 2: Preferences - Remaining Tasks

### 1. Wire Up "Launch at Login"
**Status**: Not implemented
**Priority**: High

Currently the toggle exists but doesn't actually register/unregister the app with macOS launch services.

**Implementation**:
- Add `SMAppService` import to AppDelegate
- Create `setLaunchAtLogin(_ enabled: Bool)` method using `SMAppService.mainApp.register()` / `unregister()`
- Observe `@AppStorage(SettingsKeys.launchAtLogin)` changes in AppDelegate
- Handle errors and log appropriately

### 2. Wire Up "Show Menu Bar Icon"
**Status**: Not implemented
**Priority**: Medium

Currently the toggle exists but MenuBarExtra visibility can't be easily toggled at runtime.

**Options**:
- Option A: Keep MenuBarExtra always visible, remove this setting
- Option B: Switch to manual NSStatusItem that can be hidden/shown
- Option C: Restart app when this setting changes (not ideal UX)

**Decision needed**: Which approach to take?

### 3. Wire Up "Show Debug Tools"
**Status**: Not implemented
**Priority**: Low

The toggle exists but doesn't hide/show the "Toggle Debug" menu item.

**Implementation**:
- Read `@AppStorage(SettingsKeys.showDebugTools)` in DeepApp's MenuBarExtra
- Conditionally show/hide the "Toggle Debug" button based on this value
- May need to use `@State` or pass AppDelegate reference to observe changes

---

## Phase 5: File Indexing (Next Major Phase)

### 5.1: SQLite Foundation (First Priority)
- Create `SearchStore` actor with thread-safe access
- Design schema for files table + FTS5 full-text search
- Migration system for schema updates
- Basic CRUD operations

### 5.2: File Indexer
- `FileIndexer` actor with streaming directory traversal
- Read folders from `IndexingStore.shared.paths`
- Metadata extraction (name, path, size, dates, UTI)
- Content extraction for text files
- Hash-based change detection (skip unchanged files)
- Progress reporting

### 5.3: File Search Provider
- Replace `StubSearchProvider` with `FileSearchProvider`
- Query SQLite with FTS5
- Ranking algorithm (recency, frequency, fuzzy match)
- Return real files from disk

### 5.4: File Watcher (Later)
- FSEvents integration
- Incremental reindexing on file changes
- Debouncing for rapid changes
- Handle renames, moves, deletes

---

## Future Enhancements (Phase 6+)

### Additional Search Providers
- Applications (`.app` bundles)
- System Preferences
- Contacts (with permission)
- Calendar events (with permission)
- Browser bookmarks

### UI Improvements
- Quick Look preview implementation (currently stubbed)
- File thumbnails in detail panel
- Highlighted search matches in results
- Syntax highlighting for code files
- Custom icons per file type

### Power User Features
- Search filters (type:pdf, modified:today)
- Search scopes (limit to specific folders)
- Custom hotkey configuration
- Exclude patterns (.git, node_modules)
- Fuzzy matching improvements
