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

    /// The index of the item in search result.
    @State private var selectedIndex = 0

    /// Closure to dismiss/hide the panel
    let onDismiss: () -> Void

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
                                insertion: .opacity.combined(with: .offset(y: -10)),
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
        .onKeyPress(.escape) {
            .ignored
        }
    }

    private var searchBar: some View {
        SearchBarView(query: $viewModel.query)
    }

    private var resultsPanel: some View {
        ScrollView {
            ScrollViewReader { proxy in
                VStack(spacing: 0) {
                    if viewModel.results.isEmpty {
                        EmptyStateResult()
                    } else {
                        ForEach(Array(viewModel.results.enumerated()), id: \.element) { index, result in
                            ResultRow(
                                sysName: result.type.icon,
                                title: result.title,
                                subtitle: result.subtitle,
                                isSelected: index == selectedIndex
                            )
                            .id(index)
                            .onTapGesture {
                                selectedIndex = index
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
        .frame(minHeight: 250, maxHeight: 450)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.deepSearchView, style: .continuous)
                .fill(.regularMaterial)
        )
        .clipShape(RoundedRectangle(
            cornerRadius: DesignSystem.Radius.deepSearchView,
            style:
            .continuous
        ))
        .padding(.top, 6) // gap between bar and panel
    }

    private func focusSearchField() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            isSearchFocused = true
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

    @FocusState var isFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Deep", text: $query)
                .textFieldStyle(.plain)
                .font(.system(size: 22, weight: .medium))
                .focused($isFocused)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .frame(minWidth: 620)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.deepSearchView, style: .continuous)
                .fill(.regularMaterial)
        )
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
            .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)

            Divider()
                .padding(.leading, 44)
        }
    }
}

#Preview {
    DeepSearchView(onDismiss: {})
}
