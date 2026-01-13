# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Deep is a fast, system-wide search interface for macOS designed to help users find what they want instantly. This is a native macOS application built with SwiftUI.

## Build Commands

### Building the Project
```bash
xcodebuild -project Deep.xcodeproj -scheme Deep -configuration Debug build
```

### Building for Release
```bash
xcodebuild -project Deep.xcodeproj -scheme Deep -configuration Release build
```

### Running Tests
```bash
# Run all tests
xcodebuild test -project Deep.xcodeproj -scheme Deep

# Run unit tests only
xcodebuild test -project Deep.xcodeproj -scheme Deep -only-testing:DeepTests

# Run UI tests only
xcodebuild test -project Deep.xcodeproj -scheme Deep -only-testing:DeepUITests

# Run a specific test
xcodebuild test -project Deep.xcodeproj -scheme Deep -only-testing:DeepTests/DeepTests/testExample
```

### Opening in Xcode
```bash
open Deep.xcodeproj
```

## Architecture

### High-Level Overview

Deep is a Spotlight-style search app with:
- **AppDelegate**: Manages NSPanel lifecycle and global hotkey (Carbon API)
- **SwiftUI**: UI layer with MenuBarExtra (no WindowGroup to avoid ghost windows)
- **State Management**: `@Observable` AppState for mode switching
- **Persistence**: IndexingStore for folder paths, UserDefaults for settings

### Project Structure

```
Deep/
├── DeepApp.swift           # @main entry, MenuBarExtra definition
├── AppDelegate.swift       # Panel lifecycle, hotkey registration
├── AppState.swift          # @Observable app state (setup/main/debug modes)
├── RootView.swift          # Root container, handles double-escape, mode switching
├── ContentView.swift       # Main search UI
├── SetupView.swift         # First-run onboarding
├── DebugView.swift         # Developer diagnostics
├── SpotlightPanel.swift    # Custom NSPanel with canBecomeKey override
├── Settings/
│   └── SettingsView.swift  # Preferences window
├── Models/
│   └── IndexedPath.swift   # Represents a directory to index
├── Stores/
│   └── IndexingStore.swift # Manages list of paths to index (@Observable)
├── Utilities/
│   ├── Logger.swift        # AppLogger with categories
│   └── SettingsKeys.swift  # Constants for @AppStorage keys
└── Assets.xcassets/
```

Test targets:
- `DeepTests/` - Unit tests
- `DeepUITests/` - UI tests

### Key Architecture Decisions

**Panel Management**:
- Custom `SpotlightPanel` subclass with `.borderless` style mask
- Overrides `canBecomeKey` to accept keyboard focus despite being borderless
- `AppDelegate` creates panel manually (not via SwiftUI WindowGroup)
- `MenuBarExtra` used instead of `WindowGroup` to avoid ghost windows

**Global Hotkey**:
- Registered via Carbon `RegisterEventHotKey` API (Cmd+Shift+Space)
- No Accessibility permissions required (unlike NSEvent global monitors)
- Handler calls `AppDelegate.togglePanel()`

**State Management**:
- `AppState` is `@Observable` and injected via `.environment(appState)`
- Modes: `.setup` (first run), `.main` (search), `.debug` (diagnostics)
- `RootView` switches content based on `appState.mode`

**Settings & Persistence**:
- Settings use SwiftUI `@AppStorage` with `SettingsKeys` constants
- `IndexingStore.shared` persists paths as JSON in UserDefaults
- `IndexedPath` is Codable for easy serialization

**Logging**:
- `AppLogger` wraps `os.Logger` with categories (.app, .ui, .indexing, etc.)
- All lifecycle events, errors, and state changes are logged

### Key Configuration

- **Platform**: macOS 26.2+
- **Swift Version**: 5.0
- **Bundle Identifier**: aadishivmalhotra.Deep
- **LSUIElement**: true (no Dock icon, menu bar only)
- **App Sandbox**: Enabled with hardened runtime
- **Code Signing**: Automatic

### Important Notes

- **No WindowGroup**: Using MenuBarExtra avoids SwiftUI creating default windows
- **Focus Management**: `appState.focusSearchTrigger` increments to refocus search field
- **Double-Escape**: Handled in RootView with 500ms time window
- **Future Indexing**: Phase 5 will read from `IndexingStore.shared.paths` to know what to index
