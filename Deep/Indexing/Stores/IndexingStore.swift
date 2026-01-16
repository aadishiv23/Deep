//
//  IndexingStore.swift
//  Deep
//
//  Created by Aadi Shiv Malhotra on 1/12/26.
//

import Foundation
import Observation

/// Manages the list of directories to index.
/// Phase 5 will read from this to know what to index.
@Observable
final class IndexingStore {
    
    static let shared = IndexingStore()
    
    private let storageKey = "indexing.paths"
    
    /// List of paths to index.
    var paths: [IndexedPath] = [] {
        didSet {
            savePaths()
        }
    }
    
    private init() {
        loadPaths()
    }
    
    // MARK: - Path Methods

    /// Add a new path to index
    func addPath(_ path: String) {
        guard !paths.contains(where: { $0.path == path }) else {
            AppLogger.warning("Path already exists: \(path)", category: .indexing)
            return
        }

        let indexedPath = IndexedPath(path: path)
        paths.append(indexedPath)
        AppLogger.info("Added indexing path: \(path)", category: .indexing)
    }

    /// Remove a path from indexing
    func removePath(_ indexedPath: IndexedPath) {
        paths.removeAll { $0.id == indexedPath.id }
        AppLogger.info("Removed indexing path: \(indexedPath.path)", category: .indexing)
    }

    /// Toggle a path's enabled state
    func togglePath(_ indexedPath: IndexedPath) {
        if let index = paths.firstIndex(where: { $0.id == indexedPath.id }) {
            let updated = IndexedPath(path: indexedPath.path, isEnabled: !indexedPath.isEnabled)
            paths[index] = updated
            AppLogger.info("Toggled path \(indexedPath.path) to \(updated.isEnabled)", category: .indexing)
        }
    }

    // MARK: - Persistence

    private func savePaths() {
        do {
            let data = try JSONEncoder().encode(paths)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            AppLogger.error("Failed to save indexing paths: \(error)", category: .indexing)
        }
    }

    private func loadPaths() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            // Start with empty list - user will add folders manually
            paths = []
            AppLogger.info("No saved paths, starting with empty list", category: .indexing)
            return
        }

        do {
            paths = try JSONDecoder().decode([IndexedPath].self, from: data)
            AppLogger.info("Loaded \(paths.count) indexing paths", category: .indexing)
        } catch {
            AppLogger.error("Failed to load indexing paths: \(error)", category: .indexing)
            paths = []
        }
    }
}
