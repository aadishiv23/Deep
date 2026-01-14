# Deep Plan

**Note**: This document has been superseded by `PHASES.md` which contains the complete roadmap.

See `TODO.md` for current in-progress tasks.

---

## Legacy Plan (Historical Reference)

This plan builds from the current Spotlight-style shell and the earlier LightSpot
roadmap/skeleton references provided in `/Users/aadishivmalhotra/Downloads/ROADMAP.md`
and `/Users/aadishivmalhotra/Downloads/REBUILD_SKELETON.md`. It focuses first on
the next three user-facing milestones: setup/debug views, preferences, and UI polish.

## Phase 0: Baseline (Done)

- Global hotkey (Cmd+Shift+Space) and floating panel
- Double-escape dismissal
- Menu bar icon for show/quit
- `@Observable` app state with root view switching

## Phase 1: Setup + Debug Views (Next)

Goal: Provide a first-run flow and a place to inspect app state during development.

Deliverables
- `SetupView` with onboarding content and a basic "Continue" action
- `DebugView` showing app state and basic diagnostics (mode, hotkey status)
- `RootView` switches modes based on `AppState.mode`

Tasks
- Create `Deep/SetupView.swift` and `Deep/DebugView.swift`
- Add state transitions in `AppState` (e.g., `completeSetup()`, `enterDebug()`)
- Add a temporary debug toggle (menu bar item or key command)
- Replace placeholder texts in `RootView` with real views

Acceptance
- First run shows Setup; subsequent runs go to Main
- Debug view is reachable and shows live state
- No regressions in hotkey and panel behavior

## Phase 2: Preferences Window

Goal: Let users control core settings without editing code.

Deliverables
- Preferences window (standard macOS settings UI)
- Persistent settings storage

Tasks
- Add `SettingsView` with sections:
  - General: launch at login, show/hide menu bar icon
  - Hotkey: display current hotkey (read-only for now)
  - Indexing (placeholder): list of folders and toggle
- Add a `SettingsStore` (use `@AppStorage` or a small settings model)
- Add a menu bar item "Preferences..." that opens the settings window

Acceptance
- Preferences window opens from menu bar
- Settings persist across launches

## Phase 3: UI Polish

Goal: Make the panel feel more like Spotlight and improve usability.

Deliverables
- Focused search field on show
- Visual styling upgrades (spacing, typography, background)
- Smooth show/hide animation

Tasks
- Refine `DeepSearchView` layout for search-first interaction
- Consider panel appearance tweaks:
  - `panel.isOpaque = false` and a custom background
  - `panel.titleVisibility = .hidden` (already done)
- Add subtle appearance animation on show
- Ensure Escape handling does not interfere with text editing

Acceptance
- Panel appears with focus in the search field every time
- Visual layout looks intentional and polished
- No input lag when typing

## Phase 4: Architecture Foundation (From Skeleton Doc)

Goal: Establish clean layers before indexing and providers.

Deliverables
- Domain / Data / Presentation separation
- Search pipeline with cancellation

Tasks
- Add `SearchViewModel`, `SearchCoordinator`, and `SearchService`
- Define `SearchQuery` and `UnifiedSearchResult`
- Stub `SearchProvider` protocol and a placeholder provider

Acceptance
- Search flow is async, cancellable, and testable
- UI only depends on view model outputs

## Phase 5: Indexing + Providers (From Roadmap)

Goal: File indexing and search at scale, then expand sources.

Tasks (sequenced)
- SQLite `SearchStore` actor + schema/migrations
- `FileIndexer` actor with streaming extraction
- `FileWatcher` with FSEvents
- Performance tuning: parallel indexing + hash-based reindexing
- Optional providers (messages, notes, etc.)

Acceptance
- Index builds on a sample directory and returns results fast
- Reindexing is incremental and stable

## Open Questions

- Do we target macOS 14+ only, or maintain a macOS 13 fallback?
- Do we want an always-on background indexer (menu app only or launch agent)?
- Which features belong in v0.1 vs v0.2?
