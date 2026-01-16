# Deep

A fast, Spotlight-style search interface for macOS built with SwiftUI.

## Current Status

Deep is a **polished search UI** with keyboard navigation, split-view details, and clean architecture - ready for real file indexing.

**What works today:**
- Global hotkey (Cmd+Shift+Space) to open search panel
- Keyboard-first navigation (arrows, Enter, Space, Cmd+R)
- Split-view layout with result details (metadata, actions)
- Async search architecture with mock data
- Settings window for folder selection

**Next up:**
- SQLite-based file indexing
- Real file search (replacing mock data)
- FSEvents for live updates

See [PROGRESS.md](PROGRESS.md) for detailed status.

---

## Vision

Deep will evolve into a unified search layer across:

- **Files and content** - Fast local indexing with full-text search
- **System data** - Apps, preferences, and settings
- **User data** - Notes, messages, calendar, contacts (with permission)
- **Smart ranking** - Usage patterns, recency, and context-aware results

The goal is search that feels instant, predictable, and deeply integrated with how you work.

---

## Documentation

- [PROGRESS.md](PROGRESS.md) - Current status, what's done, what's next
- [PHASES.md](PHASES.md) - Development roadmap with all phases
- [TODO.md](TODO.md) - Immediate tasks and priorities
- [CLAUDE.md](CLAUDE.md) - Build commands and architecture overview
- [MODELS.md](MODELS.md) - Data model specifications

---

## Quick Start

### Build & Run
```bash
# Build
xcodebuild -project Deep.xcodeproj -scheme Deep -configuration Debug build

# Run
open Deep.xcodeproj
# Then press Cmd+R in Xcode
```

### Usage
1. Launch Deep.app
2. Press **Cmd+Shift+Space** to open search
3. Type to search (currently shows mock results)
4. Use **↑↓** to navigate, **Enter** to open
5. Press **Escape** twice to close

---

## Architecture

Deep is a native macOS app built with:
- **SwiftUI** for UI
- **AppKit** for panel management and global hotkey (Carbon API)
- **Observation framework** for reactive state (`@Observable`)
- **Async/await** for non-blocking search

### Key Components
- `SpotlightPanel` - Custom borderless `NSPanel` with keyboard focus
- `DeepSearchView` - Main search UI with split-view layout
- `SearchProvider` - Protocol for pluggable search backends
- `IndexingStore` - Manages folders to index (persisted to UserDefaults)

See [CLAUDE.md](CLAUDE.md) for detailed architecture notes.

---

## License

MIT (or whatever license you choose)
