//
//  StubSearchProvider.swift
//  Deep
//
//  Created by Aadi Shiv Malhotra on 1/13/26.
//

import Foundation

/// Stub search provider that returns fake results for testing
final class StubSearchProvider: SearchProviding {
    let name = "Stub Provider"

    func search(query: String) async throws -> [SearchResult] {
        // Simulate network/disk delay
        try await Task.sleep(for: .milliseconds(50))

        // Filter mock results by query
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return []
        }

        return mockResults.filter { result in
            result.title.localizedCaseInsensitiveContains(trimmed) ||
                result.subtitle.localizedCaseInsensitiveContains(trimmed)
        }
        .sorted { $0.relevanceScore > $1.relevanceScore }
    }

    func cancelSearch() {
        // Nothing to cancel in stub implementation
    }

    private let mockResults: [SearchResult] = [
        SearchResult(
            id: UUID(),
            title: "DeepSearchView.swift",
            subtitle: "Deep/Deep",
            path: URL(fileURLWithPath: "/Users/.../Deep/DeepSearchView.swift"),
            type: .code,
            modifiedDate: Date().addingTimeInterval(-3600), // 1 hour ago
            createdDate: Date().addingTimeInterval(-86400 * 7), // 1 week ago
            size: 24_576,
            relevanceScore: 1.0
        ),
        SearchResult(
            id: UUID(),
            title: "AppDelegate.swift",
            subtitle: "Deep/Deep",
            path: URL(fileURLWithPath: "/Users/.../Deep/AppDelegate.swift"),
            type: .code,
            modifiedDate: Date().addingTimeInterval(-7200), // 2 hours ago
            createdDate: Date().addingTimeInterval(-86400 * 14), // 2 weeks ago
            size: 12_288,
            relevanceScore: 0.95
        ),
        SearchResult(
            id: UUID(),
            title: "Deep.xcodeproj",
            subtitle: "Desktop/SwiftProjects/Deep",
            path: URL(fileURLWithPath: "/Users/.../Deep.xcodeproj"),
            type: .folder,
            modifiedDate: Date().addingTimeInterval(-300), // 5 min ago
            createdDate: Date().addingTimeInterval(-86400 * 30), // 1 month ago
            size: 4096,
            relevanceScore: 0.9
        ),
        SearchResult(
            id: UUID(),
            title: "Design_Assets.figma",
            subtitle: "Documents/Projects",
            path: URL(fileURLWithPath: "/Users/.../Design_Assets.figma"),
            type: .file,
            modifiedDate: Date().addingTimeInterval(-1800), // 30 min ago
            createdDate: Date().addingTimeInterval(-86400 * 5), // 5 days ago
            size: 524_288,
            relevanceScore: 0.85
        ),
        SearchResult(
            id: UUID(),
            title: "Meeting_Notes.pdf",
            subtitle: "Documents",
            path: URL(fileURLWithPath: "/Users/.../Meeting_Notes.pdf"),
            type: .pdf,
            modifiedDate: Date().addingTimeInterval(-43200), // 12 hours ago
            createdDate: Date().addingTimeInterval(-86400 * 10), // 10 days ago
            size: 2_048_000,
            relevanceScore: 0.8
        ),
        SearchResult(
            id: UUID(),
            title: "Xcode.app",
            subtitle: "Applications",
            path: URL(fileURLWithPath: "/Applications/Xcode.app"),
            type: .application,
            modifiedDate: Date().addingTimeInterval(-86400 * 2), // 2 days ago
            createdDate: Date().addingTimeInterval(-86400 * 180), // 6 months ago
            size: 15_728_640_000, // ~15GB
            relevanceScore: 0.75
        ),
        SearchResult(
            id: UUID(),
            title: "Screenshot.png",
            subtitle: "Desktop",
            path: URL(fileURLWithPath: "/Users/.../Screenshot.png"),
            type: .image,
            modifiedDate: Date().addingTimeInterval(-600), // 10 min ago
            createdDate: Date().addingTimeInterval(-600),
            size: 524_288,
            relevanceScore: 0.7
        ),
        SearchResult(
            id: UUID(),
            title: "Notes.md",
            subtitle: "Documents",
            path: URL(fileURLWithPath: "/Users/.../Notes.md"),
            type: .document,
            modifiedDate: Date().addingTimeInterval(-14400), // 4 hours ago
            createdDate: Date().addingTimeInterval(-86400 * 3), // 3 days ago
            size: 8192,
            relevanceScore: 0.65
        )
    ]

}

