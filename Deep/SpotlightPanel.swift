import AppKit

/// Borderless panel that can become key for keyboard input.
final class SpotlightPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
