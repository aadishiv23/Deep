//
//  AppDelegate.swift
//  Deep
//
//  Created by Aadi Shiv Malhotra on 1/10/26.
//

import AppKit
import Carbon
import SwiftUI

/// Manages the spotlight-style panel and global hotkey lifecycle.
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var panel: NSPanel?
    private var hotKeyRef: EventHotKeyRef?
    private let appState = AppState()

    /// Sets up the panel and global hotkey after the app launches.
    /// - Parameter notification: The launch notification from the system.
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppLogger.info("Application did finish launching", category: .app)
        setupPanel()
        setupHotKey()
    }
    
    /// Creates and configures the floating panel that hosts the SwiftUI root view.
    private func setupPanel() {
        AppLogger.info("Setting up spotlight panel", category: .ui)
        let panel = SpotlightPanel(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 360),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.isMovableByWindowBackground = true
        
        let rootView = RootView { [weak self] in
            self?.hidePanel()
        }
        .environment(appState)
        
        panel.contentView = NSHostingView(rootView: rootView)
        self.panel = panel
    }
    
    /// Registers the Cmd+Shift+Space global hotkey using Carbon APIs.
    private func setupHotKey() {
        AppLogger.info("Registering global hotkey", category: .app)
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )

        let handlerStatus = InstallEventHandler(
        GetApplicationEventTarget(),
            { _, _, userData -> OSStatus in
                let delegate = Unmanaged<AppDelegate>
                  .fromOpaque(userData!)
                  .takeUnretainedValue()
                delegate.togglePanel()
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            nil
        )
        if handlerStatus != noErr {
            AppLogger.error("Failed to install hotkey handler: \(handlerStatus)", category: .app)
        }

        let hotKeyID = EventHotKeyID(signature: OSType(0x44454550), id: 1) // "DEEP"
        let hotKeyStatus = RegisterEventHotKey(
            UInt32(kVK_Space),
            UInt32(cmdKey | shiftKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        if hotKeyStatus != noErr {
            AppLogger.error("Failed to register hotkey: \(hotKeyStatus)", category: .app)
        }
    }
    
    /// Shows and activates the panel.
    private func showPanel() {
        guard let panel else {
            AppLogger.warning("Show panel called before panel setup", category: .ui)
            return
        }
        AppLogger.info("Showing panel", category: .ui)
        panel.center()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true) // TODO: this iwll be deprecated in future
        appState.isPanelVisible = true
        appState.focusSearchTrigger += 1
    }
    
    /// Hides the panel without terminating the app.
    private func hidePanel() {
        if panel == nil {
            AppLogger.warning("Hide panel called before panel setup", category: .ui)
        }
        AppLogger.info("Hiding panel", category: .ui)
        panel?.orderOut(nil)
        appState.isPanelVisible = false
    }
    
    /// Toggles the panel visibility.
    private func togglePanel() {
        if panel?.isVisible == true {
            AppLogger.info("Toggling panel to hidden", category: .ui)
            hidePanel()
        } else {
            AppLogger.info("Toggling panel to visible", category: .ui)
            showPanel()
        }
    }

    // MARK: - Public Menu Actions

    /// Called from MenuBarExtra to show/toggle the panel
    func showPanelFromMenu() {
        AppLogger.info("Menu bar show panel invoked", category: .ui)
        if panel?.isVisible == true {
            hidePanel()
        } else {
            showPanel()
        }
    }

    /// Called from MenuBarExtra to toggle debug mode
    func toggleDebugFromMenu() {
        AppLogger.info("Menu bar debug toggle invoked", category: .ui)
        if appState.mode == .debug {
            appState.exitDebug()
        } else {
            appState.enterDebug()
            showPanel()
        }
    }

    /// Called from MenuBarExtra to reset setup
    func resetSetupFromMenu() {
        AppLogger.warning("Menu bar reset setup invoked", category: .app)
        appState.resetSetup()
        showPanel()
    }
}
