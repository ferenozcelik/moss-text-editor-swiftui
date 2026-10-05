import UIKit

/// `UITextView` with a placeholder, plain-text pasting and its own undo manager.
final class RichTextView: UITextView {
    var pastesPlainText = true

    /// The editor records every step here, typing included. UIKit's built-in text
    /// undo loses its steps when the editor changes the text itself (lists, renumbering).
    let editorUndoManager: UndoManager = {
        let undoManager = UndoManager()
        undoManager.levelsOfUndo = 100
        // Each step is grouped explicitly, so fast typing in one run loop cycle
        // does not merge separate steps.
        undoManager.groupsByEvent = false
        return undoManager
    }()

    override var undoManager: UndoManager? { editorUndoManager }

    let placeholderLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.isUserInteractionEnabled = false
        label.isAccessibilityElement = false
        return label
    }()

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        addSubview(placeholderLabel)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let padding = textContainer.lineFragmentPadding
        let width = bounds.width - textContainerInset.left - textContainerInset.right - padding * 2
        let size = placeholderLabel.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        placeholderLabel.frame = CGRect(
            x: textContainerInset.left + padding,
            y: textContainerInset.top,
            width: width,
            height: size.height
        )
    }

    func updatePlaceholderVisibility() {
        placeholderLabel.isHidden = textStorage.length > 0
    }

    override func paste(_ sender: Any?) {
        guard pastesPlainText, let string = UIPasteboard.general.string else {
            super.paste(sender)
            return
        }
        // Goes through the delegate and the undo manager like typed text.
        insertText(string)
    }
}
