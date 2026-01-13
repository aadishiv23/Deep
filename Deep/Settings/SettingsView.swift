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

    @State private var indexingStore = IndexingStore.shared

    var body: some View {
        TabView {
            generalTab
                .tabItem { Label("General", systemImage: "gearshape") }

            indexingTab
                .tabItem { Label("Indexing", systemImage: "tray.full") }

            developerTab
                .tabItem { Label("Developer", systemImage: "wrench.and.screwdriver") }
        }
        .scenePadding()
        .frame(minWidth: 520, idealWidth: 620, minHeight: 420, idealHeight: 520)
    }

    private var generalTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            Form {
                Section("General") {
                    Toggle("Launch at Login", isOn: $launchAtLogin)
                    Toggle("Show Menu Bar Icon", isOn: $showMenuBarIcon)
                }

                Section {
                    LabeledContent("Toggle search") {
                        Text("⌘⇧Space")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Hotkey")
                } footer: {
                    Text("Hotkey customization is coming soon.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var indexingTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            Form {
                Section {
                    if indexingStore.paths.isEmpty {
                        Text("No folders added yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(indexingStore.paths) { path in
                            HStack(alignment: .top, spacing: 12) {
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

                                Button {
                                    indexingStore.removePath(path)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } header: {
                    Text("Indexed Folders")
                } footer: {
                    Button("Add Folder…") {
                        selectFolder()
                    }
                }
            }
            .formStyle(.grouped)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var developerTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            Form {
                Section("Developer") {
                    Toggle("Show Debug Tools", isOn: $showDebugTools)
                }
            }
            .formStyle(.grouped)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
