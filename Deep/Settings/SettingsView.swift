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
    @AppStorage(SettingsKeys.accentColorChoice) private var accentColorChoiceRaw = AccentColorPalette.defaultChoice.rawValue
    @AppStorage(SettingsKeys.customAccentColorHex) private var customAccentColorHex = AccentColorPalette.defaultCustomHex

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

                Section("Appearance") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Accent Color")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        accentColorGrid
                        ColorPicker(
                            "Custom Color",
                            selection: customAccentColorBinding,
                            supportsOpacity: false
                        )
                        accentColorPreview
                    }
                    .padding(.vertical, 4)
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

    private var selectedAccentChoice: AccentColorChoice {
        AccentColorChoice(rawValue: accentColorChoiceRaw) ?? AccentColorPalette.defaultChoice
    }

    private var selectedAccentColor: Color {
        AccentColorPalette.color(for: selectedAccentChoice, customHex: customAccentColorHex)
    }

    private var customAccentColorBinding: Binding<Color> {
        Binding(
            get: {
                Color(hex: customAccentColorHex) ?? AccentColorPalette.fallbackColor
            },
            set: { newValue in
                if let hex = newValue.hexString() {
                    customAccentColorHex = hex
                }
                accentColorChoiceRaw = AccentColorChoice.custom.rawValue
            }
        )
    }

    private var accentColorGrid: some View {
        let columns = [GridItem(.adaptive(minimum: 70), spacing: 10)]
        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(AccentColorPalette.presets) { preset in
                let isSelected = preset.id == selectedAccentChoice
                Button {
                    accentColorChoiceRaw = preset.id.rawValue
                } label: {
                    VStack(spacing: 6) {
                        Circle()
                            .fill(preset.color)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.primary.opacity(isSelected ? 0.6 : 0.15), lineWidth: isSelected ? 2 : 1)
                            )
                        Text(preset.name)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isSelected ? preset.color.opacity(0.12) : Color.clear)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(preset.name)
            }
        }
    }

    private var accentColorPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Preview")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 10) {
                Image(systemName: "doc.text")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sample Result")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Tap to open")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(selectedAccentColor.opacity(0.15))
            )

            HStack(spacing: 6) {
                Image(systemName: "eye")
                Text("Details")
            }
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(selectedAccentColor.opacity(0.18))
            )
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.primary.opacity(0.04))
        )
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
