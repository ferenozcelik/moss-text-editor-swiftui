import UIKit

/// Appearance and behavior of a ``RichTextEditor``.
public struct RichTextConfiguration {
    /// Font of body text. Bold and italic variants are derived from it.
    public var bodyFont: UIFont
    /// Font of ``RichTextBlockStyle/title`` paragraphs. Title text is bold by default.
    public var titleFont: UIFont
    /// Font of ``RichTextBlockStyle/heading`` paragraphs. Heading text is bold by default.
    public var headingFont: UIFont
    public var textColor: UIColor
    public var tintColor: UIColor?
    public var lineSpacing: CGFloat
    public var paragraphSpacing: CGFloat
    /// Hanging indent of list items.
    public var listIndent: CGFloat
    public var contentInsets: UIEdgeInsets
    public var placeholder: String?
    public var placeholderColor: UIColor
    /// When `false`, the editor grows with its content instead of scrolling.
    public var isScrollEnabled: Bool
    public var showsScrollIndicator: Bool
    public var isEditable: Bool
    public var keyboardDismissMode: UIScrollView.KeyboardDismissMode
    /// Enables the system's autocorrection while typing.
    public var autocorrects: Bool
    /// Items of a toolbar shown above the keyboard, for example
    /// ``RichTextToolbarItem/defaultItems``. Empty by default, so you can place
    /// ``RichTextToolbar`` or your own controls anywhere instead.
    public var keyboardToolbarItems: [RichTextToolbarItem]
    /// Keeps undo, redo and dismiss keyboard pinned at the trailing edge of the
    /// keyboard toolbar. See ``RichTextToolbar/init(context:items:pinsActions:)``.
    public var keyboardToolbarPinsActions: Bool
    /// Turns `- `, `* ` and `1. ` typed at the start of a paragraph into lists.
    public var autoformatsLists: Bool
    /// Pastes text without its formatting, using the style at the cursor.
    public var pastesPlainText: Bool

    public init(
        bodyFont: UIFont = .systemFont(ofSize: 17),
        titleFont: UIFont = .systemFont(ofSize: 28),
        headingFont: UIFont = .systemFont(ofSize: 22),
        textColor: UIColor = .label,
        tintColor: UIColor? = nil,
        lineSpacing: CGFloat = 4,
        paragraphSpacing: CGFloat = 8,
        listIndent: CGFloat = 28,
        contentInsets: UIEdgeInsets = UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 12),
        placeholder: String? = nil,
        placeholderColor: UIColor = .placeholderText,
        isScrollEnabled: Bool = true,
        showsScrollIndicator: Bool = true,
        isEditable: Bool = true,
        keyboardDismissMode: UIScrollView.KeyboardDismissMode = .interactive,
        autocorrects: Bool = false,
        keyboardToolbarItems: [RichTextToolbarItem] = [],
        keyboardToolbarPinsActions: Bool = true,
        autoformatsLists: Bool = true,
        pastesPlainText: Bool = true
    ) {
        self.bodyFont = bodyFont
        self.titleFont = titleFont
        self.headingFont = headingFont
        self.textColor = textColor
        self.tintColor = tintColor
        self.lineSpacing = lineSpacing
        self.paragraphSpacing = paragraphSpacing
        self.listIndent = listIndent
        self.contentInsets = contentInsets
        self.placeholder = placeholder
        self.placeholderColor = placeholderColor
        self.isScrollEnabled = isScrollEnabled
        self.showsScrollIndicator = showsScrollIndicator
        self.isEditable = isEditable
        self.keyboardDismissMode = keyboardDismissMode
        self.autocorrects = autocorrects
        self.keyboardToolbarItems = keyboardToolbarItems
        self.keyboardToolbarPinsActions = keyboardToolbarPinsActions
        self.autoformatsLists = autoformatsLists
        self.pastesPlainText = pastesPlainText
    }

    public static var standard: RichTextConfiguration { RichTextConfiguration() }

    func font(for blockStyle: RichTextBlockStyle) -> UIFont {
        switch blockStyle {
        case .title: titleFont
        case .heading: headingFont
        case .body: bodyFont
        }
    }
}
