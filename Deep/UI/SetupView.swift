//
//  SetupView.swift
//  Deep
//
//  Created by Aadi Shiv Malhotra on 1/11/26.
//

import SwiftUI

struct SetupView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Welcome to Deep")
                .font(.title)
                .bold()
            
            Text("Deep is a fast, keyboard-first search layer for your Mac. You can customize indexing and permissions later in Settings.")
                .foregroundStyle(.secondary)
            
            HStack {
                 Button("Continue") {
                     AppLogger.info("Setup completed", category: .app)
                     appState.completeSetup()
                 }
                 .keyboardShortcut(.defaultAction)

                 Button("Not now") {
                     AppLogger.info("Setup skipped", category: .app)
                     appState.completeSetup()
                 }
             }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
}
