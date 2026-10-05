import UIKit
import XCTest
@testable import MossTextEditor

final class RichTextFormatterTests: XCTestCase {
    private let formatter = RichTextFormatter(configuration: .standard)

    private func text(_ string: String) -> NSMutableAttributedString {
        NSMutableAttributedString(string: string, attributes: formatter.defaultAttributes)
    }

    private func font(in text: NSAttributedString, at location: Int) -> UIFont {
        text.attribute(.font, at: location, effectiveRange: nil) as! UIFont
    }

    // MARK: - Fonts

    func testBoldAndItalicRoundTrip() {
        let boldItalic = formatter.font(for: .body, bold: true, italic: true)
        XCTAssertTrue(boldItalic.isBold)
        XCTAssertTrue(boldItalic.isItalic)

        let regular = formatter.font(for: .body, bold: false, italic: false)
        XCTAssertFalse(regular.isBold)
        XCTAssertFalse(regular.isItalic)
        XCTAssertEqual(regular.pointSize, RichTextConfiguration.standard.bodyFont.pointSize)
    }

    func testBlockStyleIsReadFromFontSize() {
        XCTAssertEqual(formatter.blockStyle(of: formatter.font(for: .title, bold: true, italic: false)), .title)
        XCTAssertEqual(formatter.blockStyle(of: formatter.font(for: .heading, bold: false, italic: true)), .heading)
        XCTAssertEqual(formatter.blockStyle(of: .systemFont(ofSize: 12)), .body)
    }

    // MARK: - Inline styles

    func testToggleBoldOnPartiallyBoldRangeMakesAllBoldThenNone() {
        let text = text("Hello world")
        formatter.toggle(.bold, in: text, range: NSRange(location: 0, length: 5))
        XCTAssertTrue(formatter.isActive(.bold, in: text, range: NSRange(location: 0, length: 5)))

        let all = NSRange(location: 0, length: text.length)
        XCTAssertFalse(formatter.isActive(.bold, in: text, range: all))
        formatter.toggle(.bold, in: text, range: all)
        XCTAssertTrue(formatter.isActive(.bold, in: text, range: all))
        formatter.toggle(.bold, in: text, range: all)
        XCTAssertFalse(formatter.isActive(.bold, in: text, range: NSRange(location: 0, length: 1)))
        XCTAssertFalse(font(in: text, at: 0).isBold)
    }

    func testUnderlineAndStrikethroughKeepOtherStyles() {
        let text = text("Hello")
        let all = NSRange(location: 0, length: text.length)
        formatter.toggle(.italic, in: text, range: all)
        formatter.toggle(.underline, in: text, range: all)
        formatter.toggle(.strikethrough, in: text, range: all)
        XCTAssertEqual(formatter.activeStyles(in: text, range: all), [.italic, .underline, .strikethrough])

        formatter.toggle(.underline, in: text, range: all)
        XCTAssertEqual(formatter.activeStyles(in: text, range: all), [.italic, .strikethrough])
    }

    // MARK: - Block styles

    func testHeadingIsBoldAndBodyDropsThatBold() {
        let text = text("Title\nBody")
        formatter.setBlockStyle(.title, in: text, range: NSRange(location: 1, length: 0))
        XCTAssertEqual(formatter.blockStyle(of: font(in: text, at: 0)), .title)
        XCTAssertTrue(font(in: text, at: 0).isBold)
        XCTAssertEqual(formatter.blockStyle(of: font(in: text, at: 6)), .body, "Other paragraphs are untouched")

        formatter.setBlockStyle(.body, in: text, range: NSRange(location: 1, length: 0))
        XCTAssertEqual(formatter.blockStyle(of: font(in: text, at: 0)), .body)
        XCTAssertFalse(font(in: text, at: 0).isBold)
    }

    func testBodyKeepsBoldOfBodyText() {
        let text = text("Body")
        let all = NSRange(location: 0, length: text.length)
        formatter.toggle(.bold, in: text, range: all)
        formatter.setBlockStyle(.body, in: text, range: all)
        XCTAssertTrue(font(in: text, at: 0).isBold)
    }

    // MARK: - Lists

    func testToggleBulletListOnAndOff() {
        let text = text("One\nTwo")
        var selection = NSRange(location: 0, length: text.length)
        formatter.toggleList(.bullet, in: text, range: selection, typingAttributes: formatter.defaultAttributes, selection: &selection)
        XCTAssertEqual(text.string, "•\tOne\n•\tTwo")
        XCTAssertEqual(selection, NSRange(location: 2, length: text.length - 2))
        let style = text.attribute(.paragraphStyle, at: 3, effectiveRange: nil) as! NSParagraphStyle
        XCTAssertEqual(style.headIndent, RichTextConfiguration.standard.listIndent)

        formatter.toggleList(.bullet, in: text, range: selection, typingAttributes: formatter.defaultAttributes, selection: &selection)
        XCTAssertEqual(text.string, "One\nTwo")
        XCTAssertEqual(selection, NSRange(location: 0, length: text.length))
    }

    func testSwitchingListStyleReplacesPrefixes() {
        let text = text("•\tOne\nTwo")
        var selection = NSRange(location: 0, length: text.length)
        formatter.toggleList(.numbered, in: text, range: selection, typingAttributes: formatter.defaultAttributes, selection: &selection)
        XCTAssertEqual(text.string, "1.\tOne\n2.\tTwo")
    }

    func testListOnEmptyText() {
        let text = text("")
        var selection = NSRange(location: 0, length: 0)
        formatter.toggleList(.numbered, in: text, range: selection, typingAttributes: formatter.defaultAttributes, selection: &selection)
        XCTAssertEqual(text.string, "1.\t")
        XCTAssertEqual(selection, NSRange(location: 3, length: 0))
    }

    func testRenumberingStartsOverAfterOtherParagraphs() {
        let text = text("5.\tA\n7.\tB\nText\n3.\tC")
        var selection = NSRange(location: text.length, length: 0)
        formatter.renumberLists(in: text, selection: &selection)
        XCTAssertEqual(text.string, "1.\tA\n2.\tB\nText\n1.\tC")
        XCTAssertEqual(selection.location, text.length)
    }

    func testRenumberingPastNine() {
        let items = (1...10).map { "1.\tItem \($0)" }.joined(separator: "\n")
        let text = text(items)
        var selection = NSRange(location: 0, length: 0)
        formatter.renumberLists(in: text, selection: &selection)
        XCTAssertTrue(text.string.hasSuffix("9.\tItem 9\n10.\tItem 10"))
    }

    // MARK: - Typing

    func testReturnContinuesNumberedList() {
        let text = text("1.\tOne")
        let result = formatter.insertNewline(in: text, at: text.length, typingAttributes: formatter.defaultAttributes)
        XCTAssertEqual(text.string, "1.\tOne\n2.\t")
        XCTAssertEqual(result?.selection, NSRange(location: text.length, length: 0))
    }

    func testReturnInMiddleOfListItemSplitsIt() {
        let text = text("•\tOneTwo\n•\tThree")
        _ = formatter.insertNewline(in: text, at: 5, typingAttributes: formatter.defaultAttributes)
        XCTAssertEqual(text.string, "•\tOne\n•\tTwo\n•\tThree")
    }

    func testReturnOnEmptyItemEndsList() {
        let text = text("1.\tOne\n2.\t")
        let result = formatter.insertNewline(in: text, at: text.length, typingAttributes: formatter.defaultAttributes)
        XCTAssertEqual(text.string, "1.\tOne\n")
        XCTAssertEqual(result?.selection, NSRange(location: text.length, length: 0))
    }

    func testReturnAfterHeadingStartsBodyText() {
        let text = text("Title")
        formatter.setBlockStyle(.title, in: text, range: NSRange(location: 0, length: 0))
        let typingAttributes = text.attributes(at: text.length - 1, effectiveRange: nil)
        let result = formatter.insertNewline(in: text, at: text.length, typingAttributes: typingAttributes)
        XCTAssertEqual(text.string, "Title\n")
        XCTAssertEqual(formatter.blockStyle(in: result?.typingAttributes ?? [:]), .body)
        XCTAssertFalse((result?.typingAttributes?[.font] as? UIFont)?.isBold ?? true)
    }

    func testReturnInPlainTextUsesDefaultBehavior() {
        let text = text("Plain")
        XCTAssertNil(formatter.insertNewline(in: text, at: text.length, typingAttributes: formatter.defaultAttributes))
        XCTAssertEqual(text.string, "Plain")
    }

    func testBackspaceAfterPrefixRemovesIt() {
        let text = text("1.\tOne\n2.\tTwo\n3.\tThree")
        let result = formatter.deleteBackward(in: text, at: 10)
        XCTAssertEqual(text.string, "1.\tOne\nTwo\n1.\tThree")
        XCTAssertEqual(result?.selection, NSRange(location: 7, length: 0))
        XCTAssertNil(formatter.deleteBackward(in: text, at: 5))
    }

    func testAutoformatLists() {
        let bullet = text("Intro\n-")
        let result = formatter.autoformatList(in: bullet, insertingSpaceAt: bullet.length, typingAttributes: formatter.defaultAttributes)
        XCTAssertEqual(bullet.string, "Intro\n•\t")
        XCTAssertEqual(result?.selection, NSRange(location: bullet.length, length: 0))

        let numbered = text("1.")
        _ = formatter.autoformatList(in: numbered, insertingSpaceAt: 2, typingAttributes: formatter.defaultAttributes)
        XCTAssertEqual(numbered.string, "1.\t")

        let plain = text("a-")
        XCTAssertNil(formatter.autoformatList(in: plain, insertingSpaceAt: 2, typingAttributes: formatter.defaultAttributes))
    }

    // MARK: - Helpers

    func testParagraphRanges() {
        XCTAssertEqual(formatter.paragraphRanges(in: "", covering: NSRange(location: 0, length: 0)), [NSRange(location: 0, length: 0)])
        XCTAssertEqual(
            formatter.paragraphRanges(in: "a\nb\nc", covering: NSRange(location: 1, length: 2)),
            [NSRange(location: 0, length: 2), NSRange(location: 2, length: 2)]
        )
        XCTAssertEqual(formatter.paragraphRanges(in: "a\n", covering: NSRange(location: 2, length: 0)), [NSRange(location: 2, length: 0)])
    }

    func testSelectionAdjustment() {
        // Insertion before the selection shifts it.
        XCTAssertEqual(RichTextFormatter.adjust(NSRange(location: 5, length: 2), replacing: NSRange(location: 0, length: 0), withLength: 2), NSRange(location: 7, length: 2))
        // Insertion after the selection leaves it.
        XCTAssertEqual(RichTextFormatter.adjust(NSRange(location: 0, length: 2), replacing: NSRange(location: 5, length: 0), withLength: 2), NSRange(location: 0, length: 2))
        // A cursor inside a removed range moves to its start.
        XCTAssertEqual(RichTextFormatter.adjust(NSRange(location: 1, length: 0), replacing: NSRange(location: 0, length: 2), withLength: 0), NSRange(location: 0, length: 0))
    }

    // MARK: - Normalizing and data

    func testNormalizingMapsForeignFontsAndKeepsTraits() {
        let foreign = NSAttributedString(string: "Hi", attributes: [.font: UIFont(name: "Georgia-Bold", size: 27)!])
        let normalized = formatter.normalized(foreign)
        let font = font(in: normalized, at: 0)
        XCTAssertEqual(formatter.blockStyle(of: font), .title)
        XCTAssertTrue(font.isBold)
        XCTAssertNotNil(normalized.attribute(.foregroundColor, at: 0, effectiveRange: nil))
    }

    func testDataRoundTrip() throws {
        let text = text("Title\n•\tItem")
        formatter.setBlockStyle(.title, in: text, range: NSRange(location: 0, length: 0))
        formatter.toggle(.italic, in: text, range: NSRange(location: 8, length: 4))
        formatter.toggle(.underline, in: text, range: NSRange(location: 8, length: 4))

        for format in [RichTextDataFormat.archive, .rtf] {
            let decoded = try NSAttributedString(richTextData: try text.richTextData(format: format), format: format)
            let normalized = formatter.normalized(decoded)
            XCTAssertEqual(normalized.string, text.string, "\(format)")
            XCTAssertEqual(formatter.blockStyle(of: font(in: normalized, at: 0)), .title, "\(format)")
            XCTAssertTrue(font(in: normalized, at: 0).isBold, "\(format)")
            XCTAssertEqual(formatter.activeStyles(in: normalized, range: NSRange(location: 8, length: 4)), [.italic, .underline], "\(format)")
            XCTAssertEqual(formatter.listStyle(in: normalized, at: 9), .bullet, "\(format)")
        }
    }
}
