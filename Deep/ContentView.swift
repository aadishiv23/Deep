//
//  ContentView.swift
//  Deep
//
//  Created by Aadi Shiv Malhotra on 12/31/25.
//

import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @FocusState private var isSearchFocused: Bool
    @State private var query: String = ""

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Deep", text: $query)
                .textFieldStyle(.plain)
                .font(.system(size: 22, weight: .medium))
                .focused($isSearchFocused)

            SettingsLink {
                Image(systemName: "gearshape")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 16, weight: .medium))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .frame(minHeight: 52)
        .frame(minWidth: 520)
        .glassEffect()
        .padding()
        .onAppear {
            if appState.isPanelVisible {
                AppLogger.info("Content view appeared; focusing search field", category: .ui)
                focusSearchField()
            }
        }
        .onChange(of: appState.focusSearchTrigger) { _ in
            if appState.isPanelVisible {
                AppLogger.info("Focus trigger updated; focusing search field", category: .ui)
                focusSearchField()
            }
        }
    }

    private func focusSearchField() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            isSearchFocused = true
        }
    }
}

#Preview {
    ContentView()
}
