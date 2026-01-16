//
//  SearchProviding.swift
//  Deep
//
//  Created by Aadi Shiv Malhotra on 1/13/26.
//

import Foundation

/// Protocol for search providers (files, apps, contacts, etc.)
protocol SearchProviding: Sendable {
    /// The name of this provider (e.g., "Files", "Applications")
    var name: String { get }

    /// Search for results matching the query
    /// - Parameter query: The search query string
    /// - Returns: Array of search results
    func search(query: String) async throws -> [SearchResult]

    /// Cancel any ongoing search operation
    func cancelSearch()
}
