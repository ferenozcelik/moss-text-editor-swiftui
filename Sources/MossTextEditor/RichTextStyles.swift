import Foundation

/// A character-level style that can be toggled on any part of the text.
public enum RichTextInlineStyle: String, CaseIterable, Hashable, Sendable {
    case bold
    case italic
    case underline
    case strikethrough
}

/// A paragraph-level text style.
///
/// Block styles are stored as the paragraph's font size, so they survive any
/// format that keeps fonts (RTF, archived `NSAttributedString`).
public enum RichTextBlockStyle: String, CaseIterable, Hashable, Sendable {
    case title
    case heading
    case body
}

/// A paragraph-level list style.
///
/// List items are plain text prefixes (`•\t`, `1.\t`) with a hanging indent,
/// so lists stay readable when the text is exported as a plain string.
public enum RichTextListStyle: String, CaseIterable, Hashable, Sendable {
    case bullet
    case numbered
}
