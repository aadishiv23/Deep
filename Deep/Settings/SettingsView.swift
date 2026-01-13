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

    // Add this
    @State private var indexingStore = IndexingStore.shared

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

          // Add this section
          Section("Indexing") {
              VStack(alignment: .leading, spacing: 8) {
                  ForEach(indexingStore.paths) { path in
                      HStack {
                          Toggle(isOn: Binding(
                              get: { path.isEnabled },
                              set: { _ in indexingStore.togglePath(path) }
                          )) {
                              VStack(alignment: .leading, spacing: 2) {
                                  Text(path.displayName)
                                      .font(.body)
                                  Text(path.path)
                                      .font(.caption)
                                      .foregroundStyle(.secondary)
                              }
                          }

                          Spacer()

                          Button(action: {
                              indexingStore.removePath(path)
                          }) {
                              Image(systemName: "minus.circle.fill")
                                  .foregroundStyle(.red)
                          }
                          .buttonStyle(.plain)
                      }
                      .padding(.vertical, 4)
                  }

                  Button("Add Folder...") {
                      selectFolder()
                  }
              }
          }

          Section("Developer") {
              Toggle("Show Debug Tools", isOn: $showDebugTools)
          }
        }
        .padding(20)
        .frame(minWidth: 500, idealWidth: 600, maxWidth: .infinity,
               minHeight: 400, idealHeight: 500, maxHeight: .infinity)
    }

    /// Opens a folder picker and adds the selected path to indexing
    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select a folder to index for search"

        if panel.runModal() == .OK, let url = panel.url {
            indexingStore.addPath(url.path)
        }
    }
}

