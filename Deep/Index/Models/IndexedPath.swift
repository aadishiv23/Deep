//
//  IndexedPath.swift
//  Deep
//
//  Created by Aadi Shiv Malhotra on 1/12/26.
//

import Foundation

/// Represents a directory path that should be indexed.
/// Phase 5 Indexing will read from IndexingStore to know what to index.
struct IndexedPath: Identifiable, Codable, Hashable {
    let id: UUID
    let path: String
    let displayName: String
    let isEnabled: Bool
    let dateAdded: Date
    
    init(path: String, isEnabled: Bool = true) {
        self.id = UUID()
        self.path = path
        self.displayName = (path as NSString).lastPathComponent
        self.isEnabled = isEnabled
        self.dateAdded = Date()
    }
    
    /// Returns the URL for this path.
    var url: URL {
        URL(fileURLWithPath: path)
    }
}
