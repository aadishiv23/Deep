//
//  SettingsView.swift
//  Deep
//
//  Created by Aadi Shiv Malhotra on 1/12/26.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage(SettingsKeys.launchAtLogin) private var launchAtLogin = false
    @AppStorage(SettingsKeys.showMenuBarIcon) private var showMenuBarIcon = true
    @AppStorage(SettingsKeys.showDebugTools) private var showDebugTools = false
    
    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                Toggle("Show Menu Bar Icon", isOn: $showMenuBarIcon)
            }
            
            Section("Hotkey") {
                HStack {
                    Text("Toggle search")
                    Spacer()
                    Text("⌘⇧Space")
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("Developer") {
                Toggle("Show Debug Tools", isOn: $showDebugTools)
            }
        }
        .padding(20)
        .frame(width: 240)
    }
}
