//
//  RootView.swift
//  Deep
//
//  Created by Aadi Shiv Malhotra on 1/10/26.
//

import AppKit
import SwiftUI

/// Root container that switches between high-level screens
/// and handles global key behaviors like double-escape dismissal.
struct RootView: View {
    
    // MARK: - States
    
    @Environment(AppState.self) private var appState
    
    let onDismiss: () -> Void
    
    @State private var lastEscapeTime: Date?
    
    @State private var keyMonitor: Any?
    
    // MARK: - Body
    
    var body: some View {
        Group {
            switch appState.mode {
            case .debug:
                Text("Debug")
                
            case .main:
                ContentView()
                
            case .setup:
                Text("Setup")
            }
        }
        .padding()
        .onAppear {
            keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if event.keyCode == 53 {//escape key code
                    handleEscape()
                    return nil
                }
                return event
            }
        }
        .onDisappear {
            if let keyMonitor {
               NSEvent.removeMonitor(keyMonitor)
               self.keyMonitor = nil
           }
        }
    }
    
    // MARK: - Private Methods
    
    /// Tracks double-escape and dismisses the panel when triggered.
    private func handleEscape() {
        let now = Date()
        
        if let last = lastEscapeTime, now.timeIntervalSince(last) < 0.5 {
            lastEscapeTime = nil
            onDismiss()
        } else {
            lastEscapeTime = now
        }
    }
}
