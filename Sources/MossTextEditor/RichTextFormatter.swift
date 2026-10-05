import UIKit

/// Applies and reads rich text styles on attributed strings.
///
/// Every mutating method keeps a selection range in sync with the edits it makes,
/// so the editor can restore the cursor afterwards.
struct RichTextFormatter {
    typealias Attributes = [NSAttributedString.Key: Any]

    static let bulletPrefix = "•\t"

    let configuration: RichTextConfiguration

    // MARK: - Attributes

    var defaultAttributes: Attributes {
        [
            .font: configuration.bodyFont,
            .foregroundColor: configuration.textColor,
            .paragraphStyle: paragraphStyle(isList: false),
        ]
    }

    func paragraphStyle(isList: Bool) -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = configuration.lineSpacing
        style.paragraphSpacing = configuration.paragraphSpacing
        if isList {
            style.headIndent = configuration.listIndent
            style.firstLineHeadIndent = 0
            style.tabStops = [NSTextTab(textAlignment: .natural, location: configuration.listIndent)]
            style.defaultTabInterval = configuration.listIndent
        }
        return style
    }

    /// Fonts are always rebuilt from the configured fonts, so pasted or decoded text
    /// ends up with the editor's typography.
    func font(for blockStyle: RichTextBlockStyle, bold: Bool, italic: Bool) -> UIFont {
        let base = configuration.font(for: blockStyle)
        var traits = base.fontDescriptor.symbolicTraits
        if bold { traits.insert(.traitBold) } else { traits.remove(.traitBold) }
        if italic { traits.insert(.traitItalic) } else { traits.remove(.traitItalic) }
        let descriptor = base.fontDescriptor.withSymbolicTraits(traits) ?? base.fontDescriptor
        return UIFont(descriptor: descriptor, size: base.pointSize)
    }

    func blockStyle(of font: UIFont) -> RichTextBlockStyle {
        RichTextBlockStyle.allCases.min { lhs, rhs in
            abs(configuration.font(for: lhs).pointSize - font.pointSize)
                < abs(configuration.font(for: rhs).pointSize - font.pointSize)
        } ?? .body
    }

    /// Fills in missing attributes and maps every font onto the configured fonts.
    func normalized(_ text: NSAttributedString) -> NSMutableAttributedString {
        let result = NSMutableAttributedString(attributedString: text)
        let fullRange = NSRange(location: 0, length: result.length)
        result.enumerateAttributes(in: fullRange) { attributes, range, _ in
            let font = attributes[.font] as? UIFont ?? configuration.bodyFont
            let normalizedFont = self.font(for: blockStyle(of: font), bold: font.isBold, italic: font.isItalic)
            result.addAttribute(.font, value: normalizedFont, range: range)
            if attributes[.foregroundColor] == nil {
                result.addAttribute(.foregroundColor, value: configuration.textColor, range: range)
            }
        }
        for paragraph in paragraphRanges(in: result.string, covering: fullRange) where paragraph.length > 0 {
            let isList = listItem(in: result, paragraph: paragraph) != nil
            result.addAttribute(.paragraphStyle, value: paragraphStyle(isList: isList), range: paragraph)
        }
        return result
    }

    // MARK: - Inline styles

    func isActive(_ style: RichTextInlineStyle, in attributes: Attributes) -> Bool {
        switch style {
        case .bold: (attributes[.font] as? UIFont)?.isBold ?? false
        case .italic: (attributes[.font] as? UIFont)?.isItalic ?? false
        case .underline: (attributes[.underlineStyle] as? Int ?? 0) != 0
        case .strikethrough: (attributes[.strikethroughStyle] as? Int ?? 0) != 0
        }
    }

    /// Whether every character in `range` has the style.
    func isActive(_ style: RichTextInlineStyle, in text: NSAttributedString, range: NSRange) -> Bool {
        guard range.length > 0 else { return false }
        var isActive = true
        text.enumerateAttributes(in: range) { attributes, _, stop in
            if !self.isActive(style, in: attributes) {
                isActive = false
                stop.pointee = true
            }
        }
        return isActive
    }

    func activeStyles(in attributes: Attributes) -> Set<RichTextInlineStyle> {
        Set(RichTextInlineStyle.allCases.filter { isActive($0, in: attributes) })
    }

    func activeStyles(in text: NSAttributedString, range: NSRange) -> Set<RichTextInlineStyle> {
        Set(RichTextInlineStyle.allCases.filter { isActive($0, in: text, range: range) })
    }

    func attributes(_ attributes: Attributes, setting style: RichTextInlineStyle, enabled: Bool) -> Attributes {
        var result = attributes
        switch style {
        case .bold, .italic:
            let font = attributes[.font] as? UIFont ?? configuration.bodyFont
            result[.font] = self.font(
                for: blockStyle(of: font),
                bold: style == .bold ? enabled : font.isBold,
                italic: style == .italic ? enabled : font.isItalic
            )
        case .underline:
            result[.underlineStyle] = enabled ? NSUnderlineStyle.single.rawValue : nil
        case .strikethrough:
            result[.strikethroughStyle] = enabled ? NSUnderlineStyle.single.rawValue : nil
        }
        return result
    }

    /// Turns the style off when the whole range already has it, on otherwise.
    func toggle(_ style: RichTextInlineStyle, in text: NSMutableAttributedString, range: NSRange) {
        guard range.length > 0 else { return }
        let enabled = !isActive(style, in: text, range: range)
        text.enumerateAttributes(in: range) { attributes, subrange, _ in
            text.setAttributes(self.attributes(attributes, setting: style, enabled: enabled), range: subrange)
        }
    }

    // MARK: - Block styles

    func blockStyle(in attributes: Attributes) -> RichTextBlockStyle {
        blockStyle(of: attributes[.font] as? UIFont ?? configuration.bodyFont)
    }

    func attributes(_ attributes: Attributes, setting blockStyle: RichTextBlockStyle) -> Attributes {
        var result = attributes
        let font = attributes[.font] as? UIFont ?? configuration.bodyFont
        let current = self.blockStyle(of: font)
        // Titles and headings are bold; leaving one drops the bold it added.
        let bold = blockStyle == .body ? (current == .body && font.isBold) : true
        result[.font] = self.font(for: blockStyle, bold: bold, italic: font.isItalic)
        return result
    }

    func setBlockStyle(_ blockStyle: RichTextBlockStyle, in text: NSMutableAttributedString, range: NSRange) {
        for paragraph in paragraphRanges(in: text.string, covering: range) where paragraph.length > 0 {
            text.enumerateAttributes(in: paragraph) { attributes, subrange, _ in
                text.setAttributes(self.attributes(attributes, setting: blockStyle), range: subrange)
            }
        }
    }

    // MARK: - Lists

    struct ListItem: Equatable {
        let style: RichTextListStyle
        /// Length of the `•\t` / `12.\t` prefix.
        let prefixLength: Int
        let number: Int?
    }

    func listItem(in text: NSAttributedString, paragraph: NSRange) -> ListItem? {
        let string = text.string as NSString
        let content = string.substring(with: NSRange(location: paragraph.location, length: contentLength(of: paragraph, in: string)))
        if content.hasPrefix(Self.bulletPrefix) {
            return ListItem(style: .bullet, prefixLength: (Self.bulletPrefix as NSString).length, number: nil)
        }
        let digits = content.prefix { $0.isASCII && $0.isNumber }
        guard !digits.isEmpty, content.dropFirst(digits.count).hasPrefix(".\t"), let number = Int(digits) else {
            return nil
        }
        return ListItem(style: .numbered, prefixLength: digits.count + 2, number: number)
    }

    func listStyle(in text: NSAttributedString, at location: Int) -> RichTextListStyle? {
        let paragraph = (text.string as NSString).paragraphRange(for: NSRange(location: location, length: 0))
        return listItem(in: text, paragraph: paragraph)?.style
    }

    static func prefix(for style: RichTextListStyle, number: Int) -> String {
        switch style {
        case .bullet: bulletPrefix
        case .numbered: "\(number).\t"
        }
    }

    /// Removes the list from the paragraphs in `range` when all of them already have
    /// `style`; otherwise turns all of them into `style` items.
    func toggleList(
        _ style: RichTextListStyle,
        in text: NSMutableAttributedString,
        range: NSRange,
        typingAttributes: Attributes,
        selection: inout NSRange
    ) {
        let paragraphs = paragraphRanges(in: text.string, covering: range)
        let removes = paragraphs.allSatisfy { listItem(in: text, paragraph: $0)?.style == style }

        // Walk backwards so earlier paragraph ranges stay valid.
        for paragraph in paragraphs.reversed() {
            if removes {
                removeListItem(in: text, paragraph: paragraph, selection: &selection)
            } else {
                makeListItem(style, in: text, paragraph: paragraph, typingAttributes: typingAttributes, selection: &selection)
            }
        }
        renumberLists(in: text, selection: &selection)
    }

    func makeListItem(
        _ style: RichTextListStyle,
        in text: NSMutableAttributedString,
        paragraph: NSRange,
        typingAttributes: Attributes,
        selection: inout NSRange
    ) {
        let existingPrefixLength = listItem(in: text, paragraph: paragraph)?.prefixLength ?? 0
        var attributes = paragraph.length > 0 ? text.attributes(at: paragraph.location, effectiveRange: nil) : typingAttributes
        attributes[.underlineStyle] = nil
        attributes[.strikethroughStyle] = nil
        attributes[.paragraphStyle] = paragraphStyle(isList: true)

        // Numbers are fixed by `renumberLists` afterwards.
        let prefix = NSAttributedString(string: Self.prefix(for: style, number: 1), attributes: attributes)
        replace(NSRange(location: paragraph.location, length: existingPrefixLength), with: prefix, in: text, selection: &selection)

        let newParagraph = NSRange(location: paragraph.location, length: paragraph.length - existingPrefixLength + prefix.length)
        text.addAttribute(.paragraphStyle, value: paragraphStyle(isList: true), range: newParagraph)
    }

    func removeListItem(in text: NSMutableAttributedString, paragraph: NSRange, selection: inout NSRange) {
        guard let item = listItem(in: text, paragraph: paragraph) else { return }
        replace(NSRange(location: paragraph.location, length: item.prefixLength), with: NSAttributedString(), in: text, selection: &selection)
        let newParagraph = NSRange(location: paragraph.location, length: paragraph.length - item.prefixLength)
        if newParagraph.length > 0 {
            text.addAttribute(.paragraphStyle, value: paragraphStyle(isList: false), range: newParagraph)
        }
    }

    /// Numbers consecutive numbered items from 1. Any other paragraph ends the list.
    func renumberLists(in text: NSMutableAttributedString, selection: inout NSRange) {
        var paragraphs = paragraphRanges(in: text.string, covering: NSRange(location: 0, length: text.length))
        var expected = 1
        var index = 0
        while index < paragraphs.count {
            let paragraph = paragraphs[index]
            guard let item = listItem(in: text, paragraph: paragraph), item.style == .numbered, let number = item.number else {
                expected = 1
                index += 1
                continue
            }
            if number != expected {
                let digitsRange = NSRange(location: paragraph.location, length: item.prefixLength - 2)
                let attributes = text.attributes(at: paragraph.location, effectiveRange: nil)
                let digits = NSAttributedString(string: String(expected), attributes: attributes)
                replace(digitsRange, with: digits, in: text, selection: &selection)
                let delta = digits.length - digitsRange.length
                if delta != 0 {
                    paragraphs = paragraphRanges(in: text.string, covering: NSRange(location: 0, length: text.length))
                }
            }
            expected += 1
            index += 1
        }
    }

    // MARK: - Typing behavior

    /// Result of an edit the formatter made in place of the text view's default behavior.
    struct EditResult {
        var selection: NSRange
        var typingAttributes: Attributes?
    }

    /// Continues or ends a list on return, and starts body text after a title or heading.
    func insertNewline(in text: NSMutableAttributedString, at location: Int, typingAttributes: Attributes) -> EditResult? {
        let string = text.string as NSString
        let paragraph = string.paragraphRange(for: NSRange(location: location, length: 0))
        let contentEnd = paragraph.location + contentLength(of: paragraph, in: string)
        var selection = NSRange(location: location, length: 0)

        if let item = listItem(in: text, paragraph: paragraph) {
            // Return on an empty item ends the list.
            if contentEnd - paragraph.location == item.prefixLength {
                removeListItem(in: text, paragraph: paragraph, selection: &selection)
                renumberLists(in: text, selection: &selection)
                var attributes = typingAttributes
                attributes[.paragraphStyle] = paragraphStyle(isList: false)
                return EditResult(selection: selection, typingAttributes: attributes)
            }
            guard location >= paragraph.location + item.prefixLength else { return nil }

            var prefixAttributes = text.attributes(at: paragraph.location, effectiveRange: nil)
            prefixAttributes[.paragraphStyle] = paragraphStyle(isList: true)
            let insertion = NSMutableAttributedString(string: "\n", attributes: typingAttributes.merging([.paragraphStyle: paragraphStyle(isList: true)]) { $1 })
            insertion.append(NSAttributedString(string: Self.prefix(for: item.style, number: (item.number ?? 0) + 1), attributes: prefixAttributes))
            replace(NSRange(location: location, length: 0), with: insertion, in: text, selection: &selection)
            renumberLists(in: text, selection: &selection)
            return EditResult(selection: selection, typingAttributes: typingAttributes)
        }

        let blockStyle = blockStyle(in: typingAttributes)
        guard blockStyle != .body, location == contentEnd else { return nil }
        replace(NSRange(location: location, length: 0), with: NSAttributedString(string: "\n", attributes: typingAttributes), in: text, selection: &selection)
        return EditResult(selection: selection, typingAttributes: attributes(typingAttributes, setting: .body))
    }

    /// Backspace right after a list prefix removes the whole prefix.
    func deleteBackward(in text: NSMutableAttributedString, at location: Int) -> EditResult? {
        let paragraph = (text.string as NSString).paragraphRange(for: NSRange(location: location, length: 0))
        guard let item = listItem(in: text, paragraph: paragraph), location == paragraph.location + item.prefixLength else {
            return nil
        }
        var selection = NSRange(location: location, length: 0)
        removeListItem(in: text, paragraph: paragraph, selection: &selection)
        renumberLists(in: text, selection: &selection)
        return EditResult(selection: selection, typingAttributes: nil)
    }

    /// Turns `-`, `*` or `1.` followed by a space at the start of a paragraph into a list item.
    func autoformatList(in text: NSMutableAttributedString, insertingSpaceAt location: Int, typingAttributes: Attributes) -> EditResult? {
        let string = text.string as NSString
        let paragraph = string.paragraphRange(for: NSRange(location: location, length: 0))
        let marker = string.substring(with: NSRange(location: paragraph.location, length: location - paragraph.location))
        let style: RichTextListStyle
        switch marker {
        case "-", "*": style = .bullet
        case "1.": style = .numbered
        default: return nil
        }
        var selection = NSRange(location: location, length: 0)
        replace(NSRange(location: paragraph.location, length: location - paragraph.location), with: NSAttributedString(), in: text, selection: &selection)
        let emptiedParagraph = (text.string as NSString).paragraphRange(for: NSRange(location: paragraph.location, length: 0))
        makeListItem(style, in: text, paragraph: emptiedParagraph, typingAttributes: typingAttributes, selection: &selection)
        renumberLists(in: text, selection: &selection)
        return EditResult(selection: selection, typingAttributes: nil)
    }

    // MARK: - Helpers

    /// Ranges of every paragraph touched by `range`, including their trailing newline.
    /// An empty last paragraph is returned as a zero-length range.
    func paragraphRanges(in string: String, covering range: NSRange) -> [NSRange] {
        let string = string as NSString
        let covered = string.paragraphRange(for: range)
        var result: [NSRange] = []
        var location = covered.location
        repeat {
            let paragraph = string.paragraphRange(for: NSRange(location: location, length: 0))
            result.append(paragraph)
            location = NSMaxRange(paragraph)
            if paragraph.length == 0 { break }
        } while location < NSMaxRange(covered)
        return result
    }

    func contentLength(of paragraph: NSRange, in string: NSString) -> Int {
        guard paragraph.length > 0 else { return 0 }
        let lastCharacter = string.character(at: NSMaxRange(paragraph) - 1)
        return CharacterSet.newlines.contains(Unicode.Scalar(lastCharacter) ?? " ") ? paragraph.length - 1 : paragraph.length
    }

    func replace(_ range: NSRange, with replacement: NSAttributedString, in text: NSMutableAttributedString, selection: inout NSRange) {
        text.replaceCharacters(in: range, with: replacement)
        selection = Self.adjust(selection, replacing: range, withLength: replacement.length)
    }

    /// Moves a selection to account for `range` being replaced by `length` characters.
    /// A cursor inside or at the start of the replaced range ends up after the replacement.
    static func adjust(_ selection: NSRange, replacing range: NSRange, withLength length: Int) -> NSRange {
        func adjusted(_ position: Int) -> Int {
            if position < range.location { return position }
            if position >= NSMaxRange(range) { return position + length - range.length }
            return range.location + length
        }
        let start = adjusted(selection.location)
        let end = selection.length == 0 ? start : max(start, adjusted(NSMaxRange(selection)))
        return NSRange(location: start, length: end - start)
    }
}

extension UIFont {
    var isBold: Bool { fontDescriptor.symbolicTraits.contains(.traitBold) }
    var isItalic: Bool { fontDescriptor.symbolicTraits.contains(.traitItalic) }
}
