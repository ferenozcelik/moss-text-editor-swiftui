import SwiftUI
import XCTest
@testable import MossTextEditor

/// Drives a real text view through the coordinator, the way the keyboard and
/// the toolbar do.
@MainActor
final class RichTextUndoTests: XCTestCase {
    private var text = NSAttributedString()
    private var textView: RichTextView!
    private var coordinator: RichTextCoordinator!

    override func setUp() async throws {
        text = NSAttributedString()
        let binding = Binding(get: { self.text }, set: { self.text = $0 })
        coordinator = RichTextCoordinator(text: binding, context: RichTextContext(), configuration: .standard)
        textView = RichTextView(frame: CGRect(x: 0, y: 0, width: 320, height: 480), textContainer: nil)
        textView.delegate = coordinator
        coordinator.textView = textView
        coordinator.apply(.standard, to: textView)
        coordinator.load(NSAttributedString())
    }

    /// Replaces text the way UIKit does for keyboard input: asks the delegate,
    /// applies the change with the typing attributes, then reports it.
    /// (`insertText` skips the delegate for a text view outside a window.)
    private func replace(_ range: NSRange, with string: String) {
        guard coordinator.textView(textView, shouldChangeTextIn: range, replacementText: string) else { return }
        textView.textStorage.replaceCharacters(in: range, with: NSAttributedString(string: string, attributes: textView.typingAttributes))
        textView.selectedRange = NSRange(location: range.location + (string as NSString).length, length: 0)
        coordinator.textViewDidChangeSelection(textView)
        coordinator.textViewDidChange(textView)
    }

    /// Types like the keyboard: one character per event.
    private func type(_ string: String) {
        for character in string {
            replace(textView.selectedRange, with: String(character))
        }
    }

    private func deleteBackward() {
        let selection = textView.selectedRange
        replace(selection.length > 0 ? selection : NSRange(location: selection.location - 1, length: 1), with: "")
    }

    private func undoSteps() -> [String] {
        var states = [textView.text ?? ""]
        while textView.editorUndoManager.canUndo {
            coordinator.undo()
            states.append(textView.text ?? "")
        }
        return states
    }

    func testTypingIsOneStepPerRun() {
        type("Hello world")
        XCTAssertEqual(undoSteps(), ["Hello world", ""])
    }

    func testNewlineAndCursorMoveStartNewSteps() {
        type("One")
        type("\n")
        type("Two")
        textView.selectedRange = NSRange(location: 0, length: 0)
        coordinator.textViewDidChangeSelection(textView)
        type("> ")
        XCTAssertEqual(undoSteps(), ["> One\nTwo", "One\nTwo", "One\n", "One", ""])
    }

    func testBackspaceRunIsOneStep() {
        type("Hello")
        deleteBackward()
        deleteBackward()
        XCTAssertEqual(undoSteps(), ["Hel", "Hello", ""])
    }

    func testBulletListStepsUndoInOrder() {
        type("- Coffee\nTea\n\nDone")
        XCTAssertEqual(textView.text, "•\tCoffee\n•\tTea\nDone")
        XCTAssertEqual(undoSteps(), [
            "•\tCoffee\n•\tTea\nDone",
            "•\tCoffee\n•\tTea\n",     // typing "Done"
            "•\tCoffee\n•\tTea\n•\t",  // return on the empty item ended the list
            "•\tCoffee\n•\tTea",       // return continued the list
            "•\tCoffee\n•\t",          // typing "Tea"
            "•\tCoffee",               // return continued the list
            "•\t",                     // typing "Coffee"
            "-",                       // "- " became a bullet
            "",                        // typing "-"
        ])
    }

    func testNumberedListRenumberingUndoes() {
        type("1. a\nb\nc")
        textView.selectedRange = NSRange(location: (textView.text as NSString).range(of: "b").location, length: 0)
        coordinator.textViewDidChangeSelection(textView)
        deleteBackward() // removes the "2." prefix, "3." becomes "1."
        XCTAssertEqual(textView.text, "1.\ta\nb\n1.\tc")
        coordinator.undo()
        XCTAssertEqual(textView.text, "1.\ta\n2.\tb\n3.\tc")
    }

    func testFormattingBetweenTypingKeepsSteps() {
        type("Hello")
        textView.selectedRange = NSRange(location: 0, length: 5)
        coordinator.textViewDidChangeSelection(textView)
        coordinator.toggle(.bold)
        textView.selectedRange = NSRange(location: 5, length: 0)
        coordinator.textViewDidChangeSelection(textView)
        type(" world")

        let formatter = coordinator.formatter
        XCTAssertTrue(formatter.isActive(.bold, in: textView.textStorage, range: NSRange(location: 0, length: 5)))

        coordinator.undo()
        XCTAssertEqual(textView.text, "Hello")
        XCTAssertTrue(formatter.isActive(.bold, in: textView.textStorage, range: NSRange(location: 0, length: 5)))

        coordinator.undo()
        XCTAssertEqual(textView.text, "Hello")
        XCTAssertFalse(formatter.isActive(.bold, in: textView.textStorage, range: NSRange(location: 0, length: 5)))

        coordinator.undo()
        XCTAssertEqual(textView.text, "")

        coordinator.redo()
        coordinator.redo()
        coordinator.redo()
        XCTAssertEqual(textView.text, "Hello world")
        XCTAssertTrue(formatter.isActive(.bold, in: textView.textStorage, range: NSRange(location: 0, length: 5)))
    }

    func testBlockStyleUndo() {
        type("Title")
        coordinator.setBlockStyle(.title)
        XCTAssertEqual(coordinator.formatter.blockStyle(in: textView.textStorage.attributes(at: 0, effectiveRange: nil)), .title)
        coordinator.undo()
        XCTAssertEqual(coordinator.formatter.blockStyle(in: textView.textStorage.attributes(at: 0, effectiveRange: nil)), .body)
        XCTAssertEqual(textView.text, "Title")
    }

    func testTypingAfterUndoClearsRedo() {
        type("abc")
        coordinator.undo()
        XCTAssertTrue(textView.editorUndoManager.canRedo)
        type("x")
        XCTAssertFalse(textView.editorUndoManager.canRedo)
    }

    func testBindingFollowsUndo() {
        type("Hi")
        XCTAssertEqual(text.string, "Hi")
        coordinator.undo()
        XCTAssertEqual(text.string, "")
    }
}
