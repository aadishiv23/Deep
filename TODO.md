# TODO

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

### 4. UI Improvements
**Status**: Needs polish
**Priority**: Medium

**Changes**:
- Increase window width from 240 to 400+ pixels (feels cramped)
- Add `.frame(minWidth: 400, minHeight: 300)` to Settings scene for proper window constraints
- Add footer/help text under "Hotkey" section: "Hotkey customization coming soon"
- Consider adding app version number at bottom

## Phase 3: UI Polish (Upcoming)

- Make DeepSearchView look like actual Spotlight (blur, rounded corners, proper layout)
- Add keyboard navigation for search results
- Smooth animations on show/hide
- Fix deprecation warning: `onChange(of:perform:)` in DeepSearchView.swift:50

## Phase 4+: Search Architecture & Indexing

Deferred until Phase 2 and 3 are complete.
