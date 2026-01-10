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
    enum Mode {
        case setup
        case main
        case debug
    }
    
    /// The current mode driving the root view.
    var mode: Mode = .main
}
