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
                .font(.system(size: 20, weight: .medium))
                .focused($isSearchFocused)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(minWidth: 520)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.white.opacity(0.15))
        )
        .padding()
        .onAppear {
            if appState.isPanelVisible {
                AppLogger.info("Content view appeared; focusing search field", category: .ui)
                isSearchFocused = true
            }
        }
        .onChange(of: appState.focusSearchTrigger) { _ in
            if appState.isPanelVisible {
                AppLogger.info("Focus trigger updated; focusing search field", category: .ui)
                isSearchFocused = true
            }
        }
    }
}

#Preview {
    ContentView()
}
