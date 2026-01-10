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

### Project Structure
- `Deep/` - Main application target containing source code and assets
  - `DeepApp.swift` - App entry point with `@main` annotation
  - `ContentView.swift` - Root SwiftUI view
  - `Assets.xcassets/` - Image and color assets
- `DeepTests/` - Unit test target
- `DeepUITests/` - UI test target

### Key Configuration
- **Platform**: macOS (deployment target: macOS 26.2)
- **Swift Version**: 5.0
- **Development Team**: 8VNWQXUY4G
- **Bundle Identifier**: aadishivmalhotra.Deep
- **App Sandbox**: Enabled with hardened runtime
- **SwiftUI Features**:
  - MainActor default isolation
  - Approachable concurrency enabled
  - Preview support enabled

### Build Settings Notes
- The project uses automatic code signing
- App Sandbox is enabled with user-selected files access (readonly)
- App Groups registration is enabled for potential future data sharing
- String catalog symbol generation is enabled for localization
