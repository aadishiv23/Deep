//
//  DeepSearchView+ViewModel.swift
//  Deep
//
//  Created by Aadi Shiv Malhotra on 1/13/26.
//

import Foundation

extension DeepSearchView {
    
    @MainActor
    @Observable
    final class ViewModel {
        
        /// The search query to be passed (eventually) to `SearchService`.
        var query: String = "" {
            didSet {
                Task {
                    await performSearch()
                }
            }
        }
        
        /// The search results returned from the provider.
        var results: [SearchResult] = []
        
        /// Whether a search is currently in progress.
        var isSearching: Bool = false
        
        /// The search provider (injected for testing)
        var searchProvider: SearchProviding
        
        /// Current search task for cancellation
        private var searchTask: Task<Void, Never>?
    
        
        init(searchProvider: SearchProviding = StubSearchProvider()) {
            self.searchProvider = searchProvider
        }
        
        /// The search query trimmed of whitespaces and newlines.
        var trimmedQuery: String {
            query.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        var hasQuery: Bool {
            !trimmedQuery.isEmpty
        }

        /// Performs the search async.
        private func performSearch() async {
            /// Cancel previous search.
            searchTask?.cancel()

            let currentQuery = trimmedQuery

            guard !currentQuery.isEmpty else {
                results = []
                isSearching = false
                return
            }

            // Set searching immediately to prevent flicker
            isSearching = true

            searchTask = Task {
                do {
                    let searchResults = try await searchProvider.search(query: currentQuery)

                    /// Only update if query hasn't changed
                    if currentQuery == trimmedQuery {
                        results = searchResults
                    }
                } catch {
                    AppLogger.error("Search failed: \(error)", category: .search)
                    results = []
                }

                isSearching = false
            }
        }
    }
}
