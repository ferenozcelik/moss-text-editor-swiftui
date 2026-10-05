import SwiftUI

/// A control of ``RichTextToolbar``.
public enum RichTextToolbarItem: Hashable, Sendable {
    case inline(RichTextInlineStyle)
    case block(RichTextBlockStyle)
    case list(RichTextListStyle)
    /// Pinned to the trailing edge unless the toolbar's `pinsActions` is `false`.
    case undo
    /// Pinned to the trailing edge unless the toolbar's `pinsActions` is `false`.
    case redo
    case divider
    /// Pinned to the trailing edge unless the toolbar's `pinsActions` is `false`.
    case dismissKeyboard

    public static let bold = Self.inline(.bold)
    public static let italic = Self.inline(.italic)
    public static let underline = Self.inline(.underline)
    public static let strikethrough = Self.inline(.strikethrough)
    public static let title = Self.block(.title)
    public static let heading = Self.block(.heading)
    public static let bulletList = Self.list(.bullet)
    public static let numberedList = Self.list(.numbered)

    public static let defaultItems: [RichTextToolbarItem] = [
        .bold, .italic, .underline, .strikethrough,
        .divider,
        .title, .heading,
        .divider,
        .bulletList, .numberedList,
        .undo, .redo,
        .dismissKeyboard,
    ]
}

/// A horizontally scrolling formatting toolbar.
///
/// Place it anywhere next to a ``RichTextEditor`` that shares the same
/// ``RichTextContext``, or let the editor show it above the keyboard with
/// ``RichTextConfiguration/keyboardToolbarItems``.
public struct RichTextToolbar: View {
    @ObservedObject private var context: RichTextContext
    private let items: [RichTextToolbarItem]
    private let pinsActions: Bool

    /// - Parameters:
    ///   - items: The controls, in order.
    ///   - pinsActions: Keeps undo, redo and dismiss keyboard at the trailing edge,
    ///     always visible while the other items scroll. When `false`, they scroll
    ///     in place with the rest.
    public init(
        context: RichTextContext,
        items: [RichTextToolbarItem] = RichTextToolbarItem.defaultItems,
        pinsActions: Bool = true
    ) {
        self.context = context
        self.items = items
        self.pinsActions = pinsActions
    }

    public var body: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(Array(scrollingItems.enumerated()), id: \.offset) { _, item in
                        view(for: item)
                    }
                }
                .padding(.horizontal, 8)
            }
            if !pinnedItems.isEmpty {
                Divider()
                    .frame(height: 24)
                HStack(spacing: 4) {
                    ForEach(pinnedItems, id: \.self) { item in
                        view(for: item)
                    }
                }
                .padding(.horizontal, 8)
            }
        }
        // Tall enough for the 36pt selected-button background plus 8pt on each side,
        // so highlighting a button never changes the layout.
        .frame(height: Self.height)
    }

    static let height: CGFloat = 52

    private static let pinnable: Set<RichTextToolbarItem> = [.undo, .redo, .dismissKeyboard]

    private var pinnedItems: [RichTextToolbarItem] {
        pinsActions ? items.filter(Self.pinnable.contains) : []
    }

    private var scrollingItems: [RichTextToolbarItem] {
        var result = pinsActions ? items.filter { !Self.pinnable.contains($0) } : items
        while result.last == .divider { result.removeLast() }
        return result
    }

    @ViewBuilder
    private func view(for item: RichTextToolbarItem) -> some View {
        switch item {
        case let .inline(style):
            ToolbarButton(isActive: context.isActive(style), accessibilityLabel: style.accessibilityLabel) {
                context.toggle(style)
            } label: {
                Image(systemName: style.systemImage)
            }
        case let .block(style):
            ToolbarButton(isActive: context.blockStyle == style, accessibilityLabel: style.accessibilityLabel) {
                context.setBlockStyle(style)
            } label: {
                Text(style.shortLabel)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
            }
        case let .list(style):
            ToolbarButton(isActive: context.listStyle == style, accessibilityLabel: style.accessibilityLabel) {
                context.toggleList(style)
            } label: {
                Image(systemName: style.systemImage)
            }
        case .undo:
            ToolbarButton(isActive: false, accessibilityLabel: "Undo") {
                context.undo()
            } label: {
                Image(systemName: "arrow.uturn.backward")
            }
            .disabled(!context.canUndo)
        case .redo:
            ToolbarButton(isActive: false, accessibilityLabel: "Redo") {
                context.redo()
            } label: {
                Image(systemName: "arrow.uturn.forward")
            }
            .disabled(!context.canRedo)
        case .divider:
            Divider()
                .frame(height: 24)
                .padding(.horizontal, 4)
        case .dismissKeyboard:
            ToolbarButton(isActive: false, accessibilityLabel: "Dismiss keyboard") {
                context.dismissKeyboard()
            } label: {
                Image(systemName: "keyboard.chevron.compact.down")
            }
        }
    }
}

private struct ToolbarButton<Label: View>: View {
    let isActive: Bool
    let accessibilityLabel: String
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    var body: some View {
        Button(action: action) {
            label()
                .font(.system(size: 17, weight: .medium))
                .frame(width: 36, height: 36)
                .foregroundStyle(isActive ? AnyShapeStyle(.tint) : AnyShapeStyle(.primary))
                .background {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(.tint.opacity(isActive ? 0.15 : 0))
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}

private extension RichTextInlineStyle {
    var systemImage: String {
        switch self {
        case .bold: "bold"
        case .italic: "italic"
        case .underline: "underline"
        case .strikethrough: "strikethrough"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .bold: "Bold"
        case .italic: "Italic"
        case .underline: "Underline"
        case .strikethrough: "Strikethrough"
        }
    }
}

private extension RichTextBlockStyle {
    var shortLabel: String {
        switch self {
        case .title: "H1"
        case .heading: "H2"
        case .body: "Aa"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .title: "Title"
        case .heading: "Heading"
        case .body: "Body"
        }
    }
}

private extension RichTextListStyle {
    var systemImage: String {
        switch self {
        case .bullet: "list.bullet"
        case .numbered: "list.number"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .bullet: "Bulleted list"
        case .numbered: "Numbered list"
        }
    }
}
