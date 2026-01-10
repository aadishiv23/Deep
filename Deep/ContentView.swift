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
        VStack(spacing: 16) {
            TextField("Search...", text: $query)
                .textFieldStyle(.roundedBorder)
                .font(.title2)
                .focused($isSearchFocused)

            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
        .onAppear {
            isSearchFocused = true
        }
        .onChange(of: appState.focusSearchTrigger) { _ in
            isSearchFocused = true
        }
    }
}

#Preview {
    ContentView()
}
