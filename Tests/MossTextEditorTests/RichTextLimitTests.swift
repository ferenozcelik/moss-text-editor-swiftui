import SwiftUI
import XCTest
@testable import MossTextEditor

@MainActor
final class RichTextLimitTests: XCTestCase {
    private var text = NSAttributedString()
    private var textView: RichTextView!
    private var coordinator: RichTextCoordinator!

    override func setUp() async throws {
        text = NSAttributedString()
        let configuration = RichTextConfiguration(maxLength: 5)
        let binding = Binding(get: { self.text }, set: { self.text = $0 })
        coordinator = RichTextCoordinator(text: binding, context: RichTextContext(), configuration: configuration)
        textView = RichTextView(frame: CGRect(x: 0, y: 0, width: 320, height: 480), textContainer: nil)
        textView.delegate = coordinator
        coordinator.textView = textView
        coordinator.apply(configuration, to: textView)
        coordinator.load(NSAttributedString())
    }

    private func replace(_ range: NSRange, with string: String) {
        guard coordinator.textView(textView, shouldChangeTextIn: range, replacementText: string) else { return }
        textView.textStorage.replaceCharacters(in: range, with: NSAttributedString(string: string, attributes: textView.typingAttributes))
        textView.selectedRange = NSRange(location: range.location + (string as NSString).length, length: 0)
        coordinator.textViewDidChange(textView)
    }

    func testTypingStopsAtMaxLength() {
        for character in "Hello world" {
            replace(textView.selectedRange, with: String(character))
        }
        XCTAssertEqual(textView.text, "Hello")
    }

    func testPasteIsCutToFit() {
        replace(textView.selectedRange, with: "Hi")
        replace(textView.selectedRange, with: " there")
        XCTAssertEqual(textView.text, "Hi th")
    }

    func testReplacingSelectionCountsFreedSpace() {
        replace(textView.selectedRange, with: "Hello")
        replace(NSRange(location: 0, length: 5), with: "Howdy")
        XCTAssertEqual(textView.text, "Howdy")
    }

    func testTextOverTheLimitCanBeShortened() {
        coordinator.load(NSAttributedString(string: "Too long"))
        textView.selectedRange = NSRange(location: 8, length: 0)
        replace(NSRange(location: 7, length: 1), with: "")
        XCTAssertEqual(textView.text, "Too lon")
        replace(textView.selectedRange, with: "g")
        XCTAssertEqual(textView.text, "Too lon")
    }

    func testPastedTextIsCutToFit() {
        // Paste goes through insertTextAskingDelegate. The pasteboard itself is
        // left out because reading it can wait for a permission prompt on CI.
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        window.addSubview(textView)
        window.makeKeyAndVisible()
        textView.becomeFirstResponder()
        textView.insertTextAskingDelegate("Hello world")
        XCTAssertEqual(textView.text, "Hello")
        XCTAssertEqual(text.string, "Hello")
        coordinator.undo()
        XCTAssertEqual(textView.text, "")
    }

    func testPrefixDoesNotSplitCharacters() {
        XCTAssertEqual(RichTextCoordinator.prefix(of: "ab👍c", maxLength: 3), "ab")
        XCTAssertEqual(RichTextCoordinator.prefix(of: "ab👍c", maxLength: 4), "ab👍")
        XCTAssertEqual(RichTextCoordinator.prefix(of: "abc", maxLength: 0), "")
    }
}
