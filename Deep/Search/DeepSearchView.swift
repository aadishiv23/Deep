//
//  DeepSearchView.swift
//  Deep
//
//  Created by Aadi Shiv Malhotra on 12/31/25.
//

import SwiftUI

struct DeepSearchView: View {
    @Environment(AppState.self) private var appState

    @FocusState private var isSearchFocused: Bool

    @State private var viewModel: ViewModel

    init() {
        self.viewModel = ViewModel()
    }

    var body: some View {
        VStack(spacing: 8) {
            searchBar

            Group {
                if viewModel.hasQuery {
                    resultsPanel
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
        .onChange(of: appState.focusSearchTrigger) { _ in
            if appState.isPanelVisible {
                focusSearchField()
            }
        }
    }

    private var searchBar: some View {
        SearchBarView(query: $viewModel.query)
    }

    private var resultsPanel: some View {
        ScrollView {
            VStack(spacing: 0) {
                if viewModel.filteredResults.isEmpty {
                    EmptyStateResult()
                } else {
                    ForEach(viewModel.filteredResults, id: \.self) { title in
                        ResultRow(sysName: "document", title: title)
                    }
                }
            }
        }
        .frame(minHeight: 250, maxHeight: 450)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.deepSearchView, style: .continuous)
                .fill(.regularMaterial)
        )
        .padding(.top, 6) // gap between bar and panel
    }

    private func focusSearchField() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            isSearchFocused = true
        }
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

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: sysName)
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.system(size: 16))
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            Divider()
                .padding(.leading, 44)
        }
    }
}

#Preview {
    DeepSearchView()
}
