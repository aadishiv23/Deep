# Split View Implementation for DeepSearchView

This document shows how to add a master-detail split layout like Raycast, with results on the left and details on the right.

## Overview

Replace the current `resultsPanel` with a split layout:
- **Left half**: Scrollable list of results
- **Right half**: Details about the selected result (metadata, actions)

---

## Changes to `resultsPanel`

Replace the existing `resultsPanel` computed property with:

```swift
private var resultsPanel: some View {
    HStack(spacing: 0) {
        // Left: Results list
        resultsList
            .frame(maxWidth: .infinity)

        Divider()

        // Right: Detail view
        resultDetailView
            .frame(maxWidth: .infinity)
    }
    .frame(minHeight: 250, maxHeight: 450)
    .background(
        RoundedRectangle(cornerRadius: DesignSystem.Radius.deepSearchView, style: .continuous)
            .fill(.regularMaterial)
    )
    .clipShape(RoundedRectangle(
        cornerRadius: DesignSystem.Radius.deepSearchView,
        style: .continuous
    ))
    .padding(.top, 6)
}
```

---

## Add `resultsList` View

```swift
private var resultsList: some View {
    ScrollView {
        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                if viewModel.filteredResults.isEmpty {
                    EmptyStateResult()
                } else {
                    ForEach(Array(viewModel.filteredResults.enumerated()), id: \.element) { index, title in
                        ResultRow(
                            sysName: "document",
                            title: title,
                            isSelected: index == selectedIndex
                        )
                        .id(index)
                        .onTapGesture {
                            // Single tap: select
                            selectedIndex = index
                        }
                        .onTapGesture(count: 2) {
                            // Double tap: open and dismiss
                            openFile(title)
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
```

---

## Add `resultDetailView` View

```swift
private var resultDetailView: some View {
    Group {
        if !viewModel.filteredResults.isEmpty {
            let selectedResult = viewModel.filteredResults[selectedIndex]
            VStack(alignment: .leading, spacing: 16) {
                // File name
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedResult)
                        .font(.system(size: 18, weight: .semibold))
                    Text("/Users/aadishivmalhotra/Documents/\(selectedResult)")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Divider()

                // Metadata
                VStack(alignment: .leading, spacing: 8) {
                    DetailRow(label: "Modified", value: "Today at 9:21 PM")
                    DetailRow(label: "Created", value: "Dec 31, 2025")
                    DetailRow(label: "Size", value: "24 KB")
                    DetailRow(label: "Kind", value: "Document")
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

                Spacer()
            }
            .padding(16)
        } else {
            Text("Select a result")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
```

---

## Add Helper Views

### DetailRow

Add this to the bottom of `DeepSearchView.swift`:

```swift
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
```

### ActionButton

```swift
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
```

---

## Behavior Changes

**Before:**
- Single tap → opens file and dismisses panel

**After:**
- Single tap → selects result and shows details
- Double tap → opens file and dismisses panel
- Enter key → still opens file and dismisses

---

## Future Enhancements

Once you have real `SearchResult` models with URLs:

1. **Dynamic metadata** - Pull from actual file attributes
2. **Highlighted matches** - Show matching text from file content
3. **File preview** - Show thumbnail or first few lines
4. **Context actions** - Copy path, move to trash, etc.

---

## Layout Ratios

Currently 50/50 split. To adjust:

```swift
// Left takes 40%, right takes 60%
resultsList
    .frame(maxWidth: .infinity)
    .frame(minWidth: 0, idealWidth: 240)

resultDetailView
    .frame(maxWidth: .infinity)
    .frame(minWidth: 0, idealWidth: 360)
```
