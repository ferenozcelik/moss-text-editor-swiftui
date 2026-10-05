import SwiftUI

/// Formatting state and actions of a ``RichTextEditor``.
///
/// Create one with `@StateObject`, pass it to the editor, and use it to build your
/// own formatting controls or to drive ``RichTextToolbar``.
@MainActor
public final class RichTextContext: ObservableObject {
    /// Inline styles at the cursor, or the ones applied to the whole selection.
    @Published public private(set) var activeStyles: Set<RichTextInlineStyle> = []
    @Published public private(set) var blockStyle: RichTextBlockStyle = .body
    @Published public private(set) var listStyle: RichTextListStyle?
    @Published public private(set) var selectedRange = NSRange(location: 0, length: 0)
    @Published public private(set) var isEditing = false
    @Published public private(set) var canUndo = false
    @Published public private(set) var canRedo = false

    weak var coordinator: RichTextCoordinator?

    public init() {}

    public func isActive(_ style: RichTextInlineStyle) -> Bool {
        activeStyles.contains(style)
    }

    public func toggle(_ style: RichTextInlineStyle) {
        coordinator?.toggle(style)
    }

    /// Applies the style to every paragraph in the selection. Choosing the current
    /// style again resets the paragraphs to body text.
    public func setBlockStyle(_ style: RichTextBlockStyle) {
        coordinator?.setBlockStyle(style == blockStyle ? .body : style)
    }

    public func toggleList(_ style: RichTextListStyle) {
        coordinator?.toggleList(style)
    }

    public func undo() {
        coordinator?.undo()
    }

    public func redo() {
        coordinator?.redo()
    }

    public func focus() {
        coordinator?.textView?.becomeFirstResponder()
    }

    public func dismissKeyboard() {
        coordinator?.textView?.resignFirstResponder()
    }

    struct State: Equatable {
        var activeStyles: Set<RichTextInlineStyle>
        var blockStyle: RichTextBlockStyle
        var listStyle: RichTextListStyle?
        var selectedRange: NSRange
        var isEditing: Bool
        var canUndo: Bool
        var canRedo: Bool
    }

    func update(with state: State) {
        // Only publish real changes so SwiftUI does not re-render on every keystroke.
        if activeStyles != state.activeStyles { activeStyles = state.activeStyles }
        if blockStyle != state.blockStyle { blockStyle = state.blockStyle }
        if listStyle != state.listStyle { listStyle = state.listStyle }
        if selectedRange != state.selectedRange { selectedRange = state.selectedRange }
        if isEditing != state.isEditing { isEditing = state.isEditing }
        if canUndo != state.canUndo { canUndo = state.canUndo }
        if canRedo != state.canRedo { canRedo = state.canRedo }
    }
}
