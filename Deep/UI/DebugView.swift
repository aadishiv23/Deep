//
//  DebugView.swift
//  Deep
//
//  Created by Aadi Shiv Malhotra on 1/11/26.
//

import SwiftUI

struct DebugView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Debug")
                .font(.title2)
                .bold()

            Text("Mode: \(appState.mode.rawValue)")
            Text("Has Completed Setup: \(appState.hasCompletedSetup ? "true" : "false")")
            Text("Focus Trigger: \(appState.focusSearchTrigger)")

            Divider()

            HStack(spacing: 12) {
                Button("Back to Main") {
                    AppLogger.info("Exiting debug mode", category: .app)
                    appState.exitDebug()
                }

                Button("Reset Setup") {
                    AppLogger.warning("Resetting setup state", category: .app)
                    appState.resetSetup()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
}
