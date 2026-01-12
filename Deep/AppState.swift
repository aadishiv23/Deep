//
//  AppState.swift
//  Deep
//
//  Created by Aadi Shiv Malhotra on 1/10/26.
//

import Foundation
import Observation

/// Global app state for deciding which root-level view to present.
@Observable
final class AppState {
    
    /// High-level UI modes for the app.
    enum Mode: String {
        case setup
        case main
        case debug
    }
    
    private enum Keys {
        static let hasCompletedSetup = "hasCompletedSetup"
    }

    /// Whether the initial setup has been completed.
    var hasCompletedSetup: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedSetup, forKey: Keys.hasCompletedSetup)
            AppLogger.info("Setup completion set: \(hasCompletedSetup)", category: .app)
        }
    }
    
    /// The current mode driving the root view.
    var mode: Mode = .main {
        didSet {
            guard oldValue != mode else { return }
            AppLogger.info("Mode changed: \(oldValue) -> \(mode)", category: .app)
        }
    }

    /// Bumps when the panel should focus the primary search field.
    var focusSearchTrigger: Int = 0

    /// Tracks whether the panel is currently visible.
    var isPanelVisible: Bool = false {
        didSet {
            guard oldValue != isPanelVisible else { return }
            AppLogger.info("Panel visibility: \(isPanelVisible)", category: .ui)
        }
    }
    
    init() {
        let stored = UserDefaults.standard.bool(forKey: Keys.hasCompletedSetup)
        self.hasCompletedSetup = stored
        self.mode = stored ? .main : .setup
    }

    func completeSetup() {
        hasCompletedSetup = true
        mode = .main
    }

    func enterDebug() {
        mode = .debug
    }

    func exitDebug() {
        mode = hasCompletedSetup ? .main : .setup
    }

    func resetSetup() {
        hasCompletedSetup = false
        mode = .setup
    }
}
