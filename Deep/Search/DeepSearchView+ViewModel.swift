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
        var query: String = ""
        
        /// Array of mock results for testing.
        private let mockResults = [
            "Deep — Preferences",
            "Project Notes",
            "README.md",
            "Design Spec",
            "Invoices 2025",
            "Meeting Notes",
            "Tasks",
            "Deep.app"
        ]
        
        /// The search query trimmed of whitespaces and newlines.
        var trimmedQuery: String {
            query.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        var hasQuery: Bool {
            !trimmedQuery.isEmpty
        }

        /// The mock results, filtered, containing the `trimmedQuery`
        var filteredResults: [String] {
            mockResults.filter { $0.localizedCaseInsensitiveContains(trimmedQuery) }
        }
    }
}
