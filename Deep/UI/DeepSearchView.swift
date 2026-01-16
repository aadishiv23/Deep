//
//  DeepSearchView.swift
//  Deep
//
//  Created by Aadi Shiv Malhotra on 12/31/25.
//

import Quartz
import SwiftUI

struct DeepSearchView: View {
    @Environment(AppState.self) private var appState

    @FocusState private var isSearchFocused: Bool

    @State private var viewModel: ViewModel
    @AppStorage(SettingsKeys.accentColorChoice) private var accentColorChoiceRaw = AccentColorPalette.defaultChoice.rawValue
    @AppStorage(SettingsKeys.customAccentColorHex) private var customAccentColorHex = AccentColorPalette.defaultCustomHex

    /// The index of the item in search result.
    @State private var selectedIndex = 0

    private var detailAvailable: Bool {
        guard !viewModel.results.isEmpty else {
            return false
        }
        let selected = viewModel.results[selectedIndex]

        // Show detail for files, folders, documents
        switch selected.type {
        case .file, .folder, .document, .code, .image, .pdf:
            return true
        case .application:
            return false
            // Add more cases here as needed (Phase 6+)
        }
    }

    private var shouldShowDetail: Bool {
        detailAvailable && appState.isDetailPanelEnabled
    }

    private var accentColor: Color {
        let choice = AccentColorChoice(rawValue: accentColorChoiceRaw) ?? AccentColorPalette.defaultChoice
        return AccentColorPalette.color(for: choice, customHex: customAccentColorHex)
    }

    /// Closure to dismiss/hide the panel
    let onDismiss: () -> Void

    private enum Layout {
        static let resultsListWidth: CGFloat = 375
        static let detailWidth: CGFloat = 375
        static let resultsPanelMinWidth: CGFloat = resultsListWidth + detailWidth
        static let resultsPanelMinHeight: CGFloat = 380
        static let resultsPanelMaxHeight: CGFloat = 480
    }

    init(onDismiss: @escaping () -> Void) {
        self.viewModel = ViewModel()
        self.onDismiss = onDismiss
    }

    var body: some View {
        VStack(spacing: 8) {
            searchBar
                .padding(.horizontal, 12)

            Group {
                if viewModel.hasQuery {
                    resultsPanel
                        .padding(.horizontal, 12)
                        .transition(
                            .asymmetric(
                                insertion: .opacity,
                                removal: .opacity.combined(with: .scale(scale: 0.98, anchor: .top))
                            )
                        )
                }
            }
            .animation(.smooth(duration: 0.25), value: viewModel.hasQuery)
        }
        .padding()
        .onAppear {
            if appState.isPanelVisible {
                focusSearchField()
            }
        }
        .onChange(of: appState.focusSearchTrigger) { _, _ in
            if appState.isPanelVisible {
                focusSearchField()
            }
        }
        .onChange(of: viewModel.results) { _, _ in
            selectedIndex = 0
        }
        .onKeyPress(.downArrow) {
            guard !viewModel.results.isEmpty else {
                return .ignored
            }
            if selectedIndex < viewModel.results.count - 1 {
                selectedIndex += 1
            }
            return .handled
        }
        .onKeyPress(.upArrow) {
            guard !viewModel.results.isEmpty else {
                return .ignored
            }
            if selectedIndex > 0 {
                selectedIndex -= 1
            }
            return .handled
        }
        .onKeyPress(.return) {
            guard !viewModel.results.isEmpty else {
                return .ignored
            }
            let selectedResult = viewModel.results[selectedIndex]
            openFile(selectedResult)
            onDismiss()
            return .handled
        }
        .onKeyPress(.space) {
            guard !viewModel.results.isEmpty else {
                return .ignored
            }
            let selectedResult = viewModel.results[selectedIndex]
            showQuickLook(for: selectedResult)
            return .handled
        }
        .onKeyPress(keys: [.init("r")], phases: .down) { press in
            guard press.modifiers.contains(.command) else {
                return .ignored
            }
            guard !viewModel.results.isEmpty else {
                return .ignored
            }
            let selectedResult = viewModel.results[selectedIndex]
            revealInFinder(selectedResult)
            return .handled
        }
        .onKeyPress(keys: [.init("d")], phases: .down) { press in
            guard press.modifiers.contains(.command) else {
                return .ignored
            }
            toggleDetailPanel()
            return .handled
        }
        .onKeyPress(.escape) {
            .ignored
        }
    }

    private var searchBar: some View {
        SearchBarView(
            query: $viewModel.query,
            isDetailPanelEnabled: appState.isDetailPanelEnabled,
            accentColor: accentColor,
            onToggleDetail: toggleDetailPanel
        )
    }

    private var resultsPanel: some View {
        HStack(spacing: 0) {
            // Left: Results list
            resultsList
                .frame(
                    minWidth: shouldShowDetail ? Layout.resultsListWidth : Layout.resultsPanelMinWidth,
                    maxWidth: shouldShowDetail ? Layout.resultsListWidth : Layout.resultsPanelMinWidth
                )

            // Right: Detail view (conditional)
            if shouldShowDetail {
                Divider()

                resultDetailView
                    .frame(width: Layout.detailWidth)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .frame(minWidth: Layout.resultsPanelMinWidth)
        .frame(minHeight: Layout.resultsPanelMinHeight, maxHeight: Layout.resultsPanelMaxHeight)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.deepSearchView, style: .continuous)
                .fill(.regularMaterial)
        )
        .clipShape(RoundedRectangle(
            cornerRadius: DesignSystem.Radius.deepSearchView,
            style: .continuous
        ))
        .padding(.top, 6)
        .animation(.smooth(duration: 0.25), value: shouldShowDetail)
    }

    private var resultsList: some View {
        ScrollView {
            ScrollViewReader { proxy in
                VStack(spacing: 0) {
                    if viewModel.results.isEmpty {
                        EmptyStateResult()
                    } else {
                        ForEach(Array(viewModel.results.enumerated()), id: \.offset) { index, result
                            in
                            ResultRow(
                                sysName: result.type.icon,
                                title: result.title,
                                subtitle: result.subtitle,
                                isSelected: index == selectedIndex,
                                accentColor: accentColor
                            )
                            .id(index)
                            .onTapGesture {
                                // Single tap: select
                                selectedIndex = index
                            }
                            .onTapGesture(count: 2) {
                                // Double tap: open and dismiss
                                openFile(result)
                                onDismiss()
                            }
                        }
                    }
                }
                .onChange(of: selectedIndex) { _, _ in
                    withAnimation(.easeInOut(duration: 0.25)) {
                        proxy.scrollTo(selectedIndex, anchor: .center)
                    }
                }
            }
        }
    }

    private var resultDetailView: some View {
        Group {
            if !viewModel.results.isEmpty {
                let selectedResult = viewModel.results[selectedIndex]
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // File name & path
                        VStack(alignment: .leading, spacing: 4) {
                            Text(selectedResult.title)
                                .font(.system(size: 18, weight: .semibold))
                            Text(selectedResult.path.path)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }

                        Divider()

                        // Metadata
                        VStack(alignment: .leading, spacing: 8) {
                            DetailRow(label: "Modified", value: selectedResult.formattedModifiedDate)
                            DetailRow(label: "Created", value: selectedResult.formattedCreatedDate)
                            DetailRow(label: "Size", value: selectedResult.formattedSize)
                            DetailRow(label: "Kind", value: selectedResult.type.rawValue.capitalized)
                        }

                        Divider()

                        // Actions
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Actions")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)

                            ActionButton(icon: "arrow.right.circle", label: "Open", shortcut: "↩")
                            ActionButton(icon: "eye", label: "Quick Look", shortcut: "Space")
                            ActionButton(icon: "folder", label: "Reveal in Finder", shortcut: "⌘R")
                        }
                    }
                    .padding(16)
                }
            }
        }
    }

    private func focusSearchField() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            isSearchFocused = true
        }
    }

    private func toggleDetailPanel() {
        withAnimation(.smooth(duration: 0.25)) {
            appState.isDetailPanelEnabled.toggle()
        }
    }

    private func openFile(_ searchResult: SearchResult) {
        // For now with mock data, just log it
        // TODO: Once we have real SearchResult with URLs, use:
        // NSWorkspace.shared.open(url)
        AppLogger.info("Opening: \(searchResult.title)", category: .ui)
    }

    private func showQuickLook(for searchResult: SearchResult) {
        // TODO: Once we have real SearchResult with URLs:
        // let panel = QLPreviewPanel.shared()
        // if panel.isVisible {
        //     panel.orderOut(nil)
        // } else {
        //     panel.makeKeyAndOrderFront(nil)
        // }
        AppLogger.info("Quick Look for: \(searchResult.title)", category: .ui)
    }

    private func revealInFinder(_ searchResult: SearchResult) {
        // TODO: Once we have real SearchResult with URLs:
        // NSWorkspace.shared.activateFileViewerSelecting([url])
        AppLogger.info("Reveal in Finder: \(searchResult.title)", category: .ui)
    }
}

// MARK: - Search Bar View

struct SearchBarView: View {

    /// The query that is being searched for.
    @Binding var query: String

    let isDetailPanelEnabled: Bool
    let accentColor: Color
    let onToggleDetail: () -> Void

    @FocusState var isFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Deep", text: $query)
                .textFieldStyle(.plain)
                .font(.system(size: 22, weight: .medium))
                .focused($isFocused)
            Spacer(minLength: 8)
            detailToggleButton
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .frame(minWidth: 675)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.deepSearchView, style: .continuous)
                .fill(.regularMaterial)
        )
    }

    private var detailToggleButton: some View {
        Button {
            onToggleDetail()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isDetailPanelEnabled ? "eye" : "eye.slash")
                Text("Details")
            }
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(isDetailPanelEnabled ? .primary : .secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isDetailPanelEnabled ? accentColor.opacity(0.18) : Color.primary.opacity(0.06))
            )
            .overlay(
                Capsule()
                    .strokeBorder(Color.primary.opacity(0.08))
            )
        }
        .buttonStyle(.plain)
        .help("Toggle detail panel (⌘D)")
        .accessibilityLabel(isDetailPanelEnabled ? "Hide details" : "Show details")
        .accessibilityHint("Toggles the detail panel")
    }
}

// MARK: - EmptyStateView

struct EmptyStateResult: View {

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)

            Text("No results")
                .font(.system(size: 15, weight: .semibold))

            Text("Try a different keyword.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 24)
        .padding(.top, 10)
    }
}

// MARK: - Result Row

/// A view representing a `SearchResult`
struct ResultRow: View {
    /// SF Symbol name.
    let sysName: String

    /// Title of RowItem.
    let title: String

    let subtitle: String

    let isSelected: Bool
    let accentColor: Color

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: sysName)
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16))

                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(isSelected ? accentColor.opacity(0.15) : Color.clear)

            Divider()
                .padding(.leading, 44)
        }
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .leading)
            Text(value)
                .font(.system(size: 12))
        }
    }
}

// MARK: - Action Button

struct ActionButton: View {
    let icon: String
    let label: String
    let shortcut: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .frame(width: 20)
            Text(label)
                .font(.system(size: 13))
            Spacer()
            Text(shortcut)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    DeepSearchView(onDismiss: {})
}
