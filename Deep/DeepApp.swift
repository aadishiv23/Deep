//
//  DeepApp.swift
//  Deep
//
//  Created by Aadi Shiv Malhotra on 12/31/25.
//

import SwiftUI

@main
struct DeepApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // MenuBarExtra doesn't create any ghost windows
        MenuBarExtra("Deep", systemImage: "magnifyingglass") {
            Button("Show Deep") {
                appDelegate.showPanelFromMenu()
            }

            Button("Toggle Debug") {
                appDelegate.toggleDebugFromMenu()
            }

            Button("Reset Setup") {
                appDelegate.resetSetupFromMenu()
            }

            Divider()
            
            SettingsLink {
                Text("Preferences…")
            }
            .keyboardShortcut(",", modifiers: .command)

            Button("Quit Deep") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        
        Settings {
            SettingsView()
        }
    }
}
