//
//  SearchResult.swift
//  Deep
//
//  Created by Aadi Shiv Malhotra on 1/13/26.
//

import SwiftUI

/// An object representing a search result that can show up in `DeepSearchView`.
struct SearchResult: Identifiable, Hashable {

    /// Unique identifier.
    let id: UUID

    /// The title of the file
    /// e/g. ,`DeepSearchView.swift`
    let title: String

    /// The subtitle.
    /// e.g., `Deep/Search` (folder path)
    let subtitle: String

    /// Full file path.
    let path: URL

    /// The type of file.
    let type: ResultType

    /// Last date file was modified, for future recency sorting.
    let modifiedDate: Date

    /// File creation date (if available)
    let createdDate: Date

    /// File size in bytes (if available)
    let size: Int64

    /// For ranking
    let relevanceScore: Double

    enum ResultType {
        case file
        case folder
        case application
        case document
        case code
        case image
        case pdf

        var icon: String {
            switch self {
            case .file: "doc.fill"
            case .folder: "folder.fill"
            case .application: "app.fill"
            case .document: "doc.text.fill"
            case .code: "chevron.left.forwardslash.chevron.right"
            case .image: "photo.fill"
            case .pdf: "doc.richtext.fill"
            }
        }

        var color: Color {
            switch self {
            case .file: .gray
            case .folder: .blue
            case .application: .purple
            case .document: .orange
            case .code: .green
            case .image: .pink
            case .pdf: .red
            }
        }
    }
}

// MARK: - Helpers

extension SearchResult {
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var formattedModifiedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: modifiedDate, relativeTo: Date())
    }

    var formattedCreatedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdDate)
    }
}

// MARK: - Mock Data

extension SearchResult {
    static let mockResults: [SearchResult] = [
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
