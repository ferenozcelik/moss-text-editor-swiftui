import SwiftUI

/// A SwiftUI rich text editor backed by `UITextView`.
///
/// ```swift
/// @State private var text = NSAttributedString()
/// @StateObject private var context = RichTextContext()
///
/// var body: some View {
///     RichTextEditor(text: $text, context: context)
/// }
/// ```
///
/// Formatting is stored in the attributed string itself. Use
/// ``Foundation/NSAttributedString/richTextData(format:)`` to persist it.
public struct RichTextEditor: View {
    @Binding private var text: NSAttributedString
    private let externalContext: RichTextContext?
    private let configuration: RichTextConfiguration
    @StateObject private var ownContext = RichTextContext()

    /// - Parameters:
    ///   - text: The edited text.
    ///   - context: Pass a context to read the formatting state or build your own
    ///     controls. The editor creates its own when omitted.
    ///   - configuration: Appearance and behavior of the editor.
    public init(
        text: Binding<NSAttributedString>,
        context: RichTextContext? = nil,
        configuration: RichTextConfiguration = .standard
    ) {
        _text = text
        externalContext = context
        self.configuration = configuration
    }

    public var body: some View {
        RichTextEditorRepresentable(
            text: $text,
            context: externalContext ?? ownContext,
            configuration: configuration
        )
    }
}

private struct RichTextEditorRepresentable: UIViewRepresentable {
    @Binding var text: NSAttributedString
    let context: RichTextContext
    let configuration: RichTextConfiguration

    func makeCoordinator() -> RichTextCoordinator {
        RichTextCoordinator(text: $text, context: context, configuration: configuration)
    }

    func makeUIView(context: Context) -> RichTextView {
        let textView = RichTextView(frame: .zero, textContainer: nil)
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        textView.allowsEditingTextAttributes = false
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        context.coordinator.textView = textView
        self.context.coordinator = context.coordinator
        context.coordinator.isUpdatingFromSwiftUI = true
        defer { context.coordinator.isUpdatingFromSwiftUI = false }
        context.coordinator.apply(configuration, to: textView)
        context.coordinator.load(text)
        return textView
    }

    func updateUIView(_ textView: RichTextView, context: Context) {
        let coordinator = context.coordinator
        coordinator.text = $text
        coordinator.context = self.context
        self.context.coordinator = coordinator
        coordinator.isUpdatingFromSwiftUI = true
        defer { coordinator.isUpdatingFromSwiftUI = false }
        coordinator.apply(configuration, to: textView)
        if !text.isEqual(to: coordinator.lastText) {
            coordinator.load(text)
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: RichTextView, context: Context) -> CGSize? {
        guard !configuration.isScrollEnabled else { return nil }
        let width = proposal.width ?? uiView.bounds.width
        guard width > 0 else { return nil }
        let height = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height
        guard let maxHeight = configuration.maxHeight else {
            return CGSize(width: width, height: height)
        }
        context.coordinator.setExceedsMaxHeight(height > maxHeight, in: uiView)
        return CGSize(width: width, height: min(height, maxHeight))
    }
}

@MainActor
final class RichTextCoordinator: NSObject, UITextViewDelegate {
    var text: Binding<NSAttributedString>
    weak var context: RichTextContext?
    weak var textView: RichTextView?
    private(set) var configuration: RichTextConfiguration
    private(set) var lastText = NSAttributedString()
    var isUpdatingFromSwiftUI = false
    private var toolbarHost: UIHostingController<AnyView>?
    /// Typing that continues this run joins the undo step that started it.
    private var typingRun: TypingRun?
    /// The text is taller than ``RichTextConfiguration/maxHeight``, so the editor scrolls.
    private var exceedsMaxHeight = false

    private struct TypingRun {
        enum Kind { case insert, delete }
        let kind: Kind
        /// Where the cursor is after the latest change of the run.
        var cursor: Int
    }

    var formatter: RichTextFormatter { RichTextFormatter(configuration: configuration) }

    init(text: Binding<NSAttributedString>, context: RichTextContext, configuration: RichTextConfiguration) {
        self.text = text
        self.context = context
        self.configuration = configuration
    }

    // MARK: - Setup

    func apply(_ configuration: RichTextConfiguration, to textView: RichTextView) {
        self.configuration = configuration
        textView.textContainerInset = configuration.contentInsets
        textView.isScrollEnabled = configuration.isScrollEnabled || exceedsMaxHeight
        textView.showsVerticalScrollIndicator = configuration.showsScrollIndicator
        textView.showsHorizontalScrollIndicator = configuration.showsScrollIndicator
        textView.isEditable = configuration.isEditable
        textView.keyboardDismissMode = configuration.keyboardDismissMode
        textView.autocorrectionType = configuration.autocorrects ? .yes : .no
        textView.pastesPlainText = configuration.pastesPlainText
        if let tintColor = configuration.tintColor {
            textView.tintColor = tintColor
        }
        textView.placeholderLabel.text = configuration.placeholder
        textView.placeholderLabel.font = configuration.bodyFont
        textView.placeholderLabel.textColor = configuration.placeholderColor
        installToolbar(in: textView)
    }

    func setExceedsMaxHeight(_ exceeds: Bool, in textView: RichTextView) {
        guard exceeds != exceedsMaxHeight else { return }
        exceedsMaxHeight = exceeds
        textView.isScrollEnabled = configuration.isScrollEnabled || exceeds
        guard exceeds else { return }
        // Keeps the cursor in view once the text starts scrolling.
        DispatchQueue.main.async {
            textView.scrollRangeToVisible(textView.selectedRange)
        }
    }

    private func installToolbar(in textView: RichTextView) {
        let items = configuration.keyboardToolbarItems
        guard !items.isEmpty, configuration.isEditable, let context else {
            textView.inputAccessoryView = nil
            toolbarHost = nil
            return
        }
        // The accessory has its own opaque bar: on iOS 26 the keyboard leaves it
        // transparent, and the text would show through behind the buttons.
        let toolbar = AnyView(
            RichTextToolbar(context: context, items: items, pinsActions: configuration.keyboardToolbarPinsActions)
                .tint(configuration.tintColor.map(Color.init(uiColor:)))
                .frame(maxWidth: .infinity)
                .background(.bar)
                .overlay(alignment: .top) { Divider() }
                .ignoresSafeArea()
        )
        if let toolbarHost {
            toolbarHost.rootView = toolbar
            return
        }
        let host = UIHostingController(rootView: toolbar)
        host.view.backgroundColor = .clear
        host.view.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 16.4, *) {
            host.safeAreaRegions = []
        }

        let container = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: RichTextToolbar.height))
        container.autoresizingMask = .flexibleWidth
        container.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: container.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        textView.inputAccessoryView = container
        toolbarHost = host
    }

    /// Shows `text` in the text view without echoing it back to the binding.
    func load(_ text: NSAttributedString) {
        lastText = text
        guard let textView else { return }
        let normalized = formatter.normalized(text)
        let selection = textView.selectedRange
        textView.textStorage.setAttributedString(normalized)
        let location = min(selection.location, normalized.length)
        textView.selectedRange = NSRange(location: location, length: 0)
        // The selection may not have moved, so UIKit would keep stale typing attributes.
        textView.typingAttributes = normalized.length == 0
            ? formatter.defaultAttributes
            : normalized.attributes(at: max(location - 1, 0), effectiveRange: nil)
        // Undo steps recorded for the previous text no longer apply.
        textView.editorUndoManager.removeAllActions()
        typingRun = nil
        textView.updatePlaceholderVisibility()
        refreshState()
    }

    // MARK: - Actions

    func toggle(_ style: RichTextInlineStyle) {
        guard let textView else { return }
        let selection = textView.selectedRange
        if selection.length == 0 {
            let enabled = !formatter.isActive(style, in: textView.typingAttributes)
            textView.typingAttributes = formatter.attributes(textView.typingAttributes, setting: style, enabled: enabled)
            refreshState()
        } else {
            perform { text, selection in
                self.formatter.toggle(style, in: text, range: selection)
                return .init(selection: selection)
            }
        }
    }

    func setBlockStyle(_ style: RichTextBlockStyle) {
        guard let textView else { return }
        perform { text, selection in
            self.formatter.setBlockStyle(style, in: text, range: selection)
            return .init(selection: selection)
        }
        textView.typingAttributes = formatter.attributes(textView.typingAttributes, setting: style)
        refreshState()
    }

    func toggleList(_ style: RichTextListStyle) {
        guard let textView else { return }
        let typingAttributes = textView.typingAttributes
        perform { text, selection in
            var selection = selection
            self.formatter.toggleList(style, in: text, range: selection, typingAttributes: typingAttributes, selection: &selection)
            return .init(selection: selection)
        }
    }

    func undo() {
        textView?.editorUndoManager.undo()
    }

    func redo() {
        textView?.editorUndoManager.redo()
    }

    /// Runs an edit on the text storage as a single undoable step.
    /// The edit returns `nil` when it did not change anything.
    @discardableResult
    private func perform(_ edit: (NSMutableAttributedString, NSRange) -> RichTextFormatter.EditResult?) -> Bool {
        guard let textView else { return false }
        let before = NSAttributedString(attributedString: textView.textStorage)
        let selectionBefore = textView.selectedRange

        textView.textStorage.beginEditing()
        let result = edit(textView.textStorage, selectionBefore)
        textView.textStorage.endEditing()

        guard let result, !textView.textStorage.isEqual(to: before) else { return result != nil }
        textView.selectedRange = result.selection
        if let typingAttributes = result.typingAttributes {
            textView.typingAttributes = typingAttributes
        }
        registerUndo(restoring: before, selection: selectionBefore)
        typingRun = nil
        textDidChange()
        return true
    }

    /// Records typing as undo steps. Consecutive insertions (or deletions) at the
    /// cursor form one step, like UIKit does; a newline, a paste, a replacement or
    /// moving the cursor starts a new one.
    private func recordTyping(in textView: RichTextView, replacing range: NSRange, with text: String) {
        let length = (text as NSString).length
        // Updates of composed (marked) text belong to the step that started them.
        if textView.markedTextRange != nil, var run = typingRun {
            run.cursor = range.location + length
            typingRun = run
            return
        }
        let kind: TypingRun.Kind = length == 0 ? .delete : .insert
        let continuesRun: Bool = {
            guard let typingRun, typingRun.kind == kind, !text.contains("\n") else { return false }
            switch kind {
            case .insert: return range.length == 0 && range.location == typingRun.cursor && length == 1
            case .delete: return NSMaxRange(range) == typingRun.cursor
            }
        }()
        if !continuesRun {
            registerUndo(restoring: NSAttributedString(attributedString: textView.textStorage), selection: textView.selectedRange)
        }
        typingRun = text.contains("\n") ? nil : TypingRun(kind: kind, cursor: range.location + length)
    }

    private func registerUndo(restoring snapshot: NSAttributedString, selection: NSRange) {
        guard let textView else { return }
        let undoManager = textView.editorUndoManager
        undoManager.beginUndoGrouping()
        defer { undoManager.endUndoGrouping() }
        undoManager.registerUndo(withTarget: textView) { [weak self] textView in
            MainActor.assumeIsolated {
                guard let self else { return }
                let current = NSAttributedString(attributedString: textView.textStorage)
                let currentSelection = textView.selectedRange
                self.typingRun = nil
                textView.textStorage.setAttributedString(snapshot)
                textView.selectedRange = selection
                // Registering while undoing records the redo step.
                self.registerUndo(restoring: current, selection: currentSelection)
                self.textDidChange()
            }
        }
    }

    // MARK: - Sync

    private func textDidChange() {
        guard let textView else { return }
        textView.updatePlaceholderVisibility()
        let snapshot = NSAttributedString(attributedString: textView.textStorage)
        lastText = snapshot
        text.wrappedValue = snapshot
        refreshState()
    }

    func refreshState() {
        guard let textView, let context else { return }
        let storage = textView.textStorage
        let selection = textView.selectedRange
        let attributes = selection.length == 0
            ? textView.typingAttributes
            : storage.attributes(at: selection.location, effectiveRange: nil)
        let state = RichTextContext.State(
            activeStyles: selection.length == 0
                ? formatter.activeStyles(in: attributes)
                : formatter.activeStyles(in: storage, range: selection),
            blockStyle: formatter.blockStyle(in: attributes),
            listStyle: formatter.listStyle(in: storage, at: selection.location),
            selectedRange: selection,
            isEditing: textView.isFirstResponder,
            canUndo: textView.editorUndoManager.canUndo,
            canRedo: textView.editorUndoManager.canRedo
        )
        if isUpdatingFromSwiftUI {
            // Publishing during a view update is not allowed.
            DispatchQueue.main.async { context.update(with: state) }
        } else {
            context.update(with: state)
        }
    }

    // MARK: - UITextViewDelegate

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard let textView = textView as? RichTextView else { return true }
        if let maxLength = configuration.maxLength, textView.markedTextRange == nil {
            let available = maxLength - (textView.textStorage.length - range.length)
            let length = (text as NSString).length
            // Edits that don't add characters always go through, so text that
            // is already too long can still be shortened.
            if length > range.length, length > available {
                // Inserts the part that fits, through this method again.
                let fitting = Self.prefix(of: text, maxLength: available)
                if !fitting.isEmpty, range == textView.selectedRange {
                    textView.insertTextAskingDelegate(fitting)
                }
                return false
            }
        }
        let handled = handleEdit(in: textView, replacing: range, with: text)
        if !handled {
            recordTyping(in: textView, replacing: range, with: text)
        }
        return !handled
    }

    /// The longest start of `string` that fits in `maxLength` UTF-16 units
    /// without splitting a character.
    static func prefix(of string: String, maxLength: Int) -> String {
        var length = 0
        var end = string.startIndex
        for character in string {
            length += character.utf16.count
            guard length <= maxLength else { break }
            end = string.index(after: end)
        }
        return String(string[..<end])
    }

    /// Edits the formatter makes in place of the default typing behavior.
    private func handleEdit(in textView: UITextView, replacing range: NSRange, with text: String) -> Bool {
        guard textView.markedTextRange == nil, textView.selectedRange.length == 0 else { return false }
        let typingAttributes = textView.typingAttributes
        let formatter = formatter
        let handled: Bool
        if text == "\n", range.length == 0 {
            handled = perform { storage, _ in
                formatter.insertNewline(in: storage, at: range.location, typingAttributes: typingAttributes)
            }
        } else if text.isEmpty, range.length == 1 {
            handled = perform { storage, _ in
                formatter.deleteBackward(in: storage, at: NSMaxRange(range))
            }
        } else if text == " ", range.length == 0, configuration.autoformatsLists {
            handled = perform { storage, _ in
                formatter.autoformatList(in: storage, insertingSpaceAt: range.location, typingAttributes: typingAttributes)
            }
        } else {
            handled = false
        }
        return handled
    }

    func textViewDidChange(_ textView: UITextView) {
        // Keeps numbered lists in order after lines are typed, pasted or deleted.
        if textView.markedTextRange == nil {
            var selection = textView.selectedRange
            textView.textStorage.beginEditing()
            formatter.renumberLists(in: textView.textStorage, selection: &selection)
            textView.textStorage.endEditing()
            if selection != textView.selectedRange {
                textView.selectedRange = selection
            }
        }
        textDidChange()
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        if let typingRun, textView.selectedRange != NSRange(location: typingRun.cursor, length: 0) {
            self.typingRun = nil
        }
        refreshState()
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        refreshState()
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        refreshState()
    }
}

#if DEBUG
private struct RichTextEditorPreview: View {
    @State private var text = NSAttributedString()
    @StateObject private var context = RichTextContext()

    var body: some View {
        RichTextEditor(
            text: $text,
            context: context,
            configuration: RichTextConfiguration(
                placeholder: "Start writing…",
                keyboardToolbarItems: RichTextToolbarItem.defaultItems
            )
        )
    }
}

#Preview {
    RichTextEditorPreview()
}
#endif
