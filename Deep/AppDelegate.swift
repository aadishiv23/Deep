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
        setupPanel()
        setupHotKey()
    }
    
    /// Creates and configures the floating panel that hosts the SwiftUI root view.
    private func setupPanel() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 360),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.hasShadow = true
        
        let rootView = RootView { [weak self] in
            self?.hidePanel()
        }
        .environment(appState)
        
        panel.contentView = NSHostingView(rootView: rootView)
        self.panel = panel
    }
    
    /// Registers the Cmd+Shift+Space global hotkey using Carbon APIs.
    private func setupHotKey() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )

        InstallEventHandler(
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

        var hotKeyID = EventHotKeyID(signature: OSType(0x44454550), id: 1) // "DEEP"
        RegisterEventHotKey(
            UInt32(kVK_Space),
            UInt32(cmdKey | shiftKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }
    
    /// Shows and activates the panel.
    private func showPanel() {
        guard let panel else { return }
        panel.center()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true) // TODO: this iwll be deprecated in future
    }
    
    /// Hides the panel without terminating the app.
    private func hidePanel() {
        panel?.orderOut(nil)
    }
    
    /// Toggles the panel visibility.
    private func togglePanel() {
        if panel?.isVisible == true {
            hidePanel()
        } else {
            showPanel()
        }
    }
}
