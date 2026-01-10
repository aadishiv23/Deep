//
//  AppState.swift
//  Deep
//
//  Created by Aadi Shiv Malhotra on 1/10/26.
//

import Observation

/// Global app state for deciding which root-level view to present.
@Observable
final class AppState {
    
    /// High-level UI modes for the app.
    enum Mode {
        case setup
        case main
        case debug
    }
    
    /// The current mode driving the root view.
    var mode: Mode = .main {
        didSet {
            AppLogger.info("Mode changed: \(oldValue) -> \(mode)", category: .app)
        }
    }

    /// Bumps when the panel should focus the primary search field.
    var focusSearchTrigger: Int = 0
}
