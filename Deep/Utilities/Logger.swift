import Foundation
import os

/// Centralized logging for the app with level-specific helpers.
enum AppLogger {
    /// Categories map to Console filters.
    enum Category: String {
        case app
        case ui
        case search
        case indexing
        case permissions
        case network
    }

    private static let subsystem = Bundle.main.bundleIdentifier ?? "Deep"

    private static func logger(for category: Category) -> Logger {
        Logger(subsystem: subsystem, category: category.rawValue)
    }

    /// Logs a standard informational message.
    static func info(_ message: String, category: Category = .app) {
        logger(for: category).log("[\(category.rawValue, privacy: .public)] \(message, privacy: .public)")
    }

    /// Logs a warning message.
    static func warning(_ message: String, category: Category = .app) {
        logger(for: category).warning("[\(category.rawValue, privacy: .public)] \(message, privacy: .public)")
    }

    /// Logs an error message.
    static func error(_ message: String, category: Category = .app) {
        logger(for: category).error("[\(category.rawValue, privacy: .public)] \(message, privacy: .public)")
    }
}
