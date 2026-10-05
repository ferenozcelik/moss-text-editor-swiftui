# MossTextEditor

[![Tests](https://github.com/ferenozcelik/moss-text-editor-swiftui/actions/workflows/tests.yml/badge.svg)](https://github.com/ferenozcelik/moss-text-editor-swiftui/actions/workflows/tests.yml)
![iOS 16+](https://img.shields.io/badge/iOS-16%2B-blue)
![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-orange)
![Swift Package Manager](https://img.shields.io/badge/SPM-compatible-brightgreen)
[![License: MIT](https://img.shields.io/badge/License-MIT-lightgrey)](LICENSE)

A rich text editor for SwiftUI. Drop it into your app to let people write with bold, italic, headings and lists.

<p align="center">
  <img src="Docs/Images/boxed-light.png" width="260" alt="Editor in a rounded box with the toolbar on top">
  <img src="Docs/Images/keyboard-dark.png" width="260" alt="Full-screen editor with the toolbar above the keyboard, in dark mode">
  <img src="Docs/Images/custom-light.png" width="260" alt="Editor with serif fonts and a paper background">
</p>

## Features

- **Bold**, *italic*, underline and ~~strikethrough~~
- Title and heading paragraphs
- Bulleted and numbered lists. Typing `- ` or `1. ` at the start of a line starts a list
- A ready-made toolbar you can put above the keyboard or anywhere on screen
- Undo and redo
- Saving and loading
- Placeholder, dark mode, custom fonts and colors

Requires iOS 16 or later.

## Installation

In Xcode, choose **File → Add Package Dependencies…** and paste:

```
https://github.com/ferenozcelik/moss-text-editor-swiftui
```

Or add it to your `Package.swift`:

```swift
.package(url: "https://github.com/ferenozcelik/moss-text-editor-swiftui", from: "1.0.0")
```

## Quick start

```swift
import MossTextEditor
import SwiftUI

struct NoteView: View {
    @State private var text = NSAttributedString()

    var body: some View {
        RichTextEditor(
            text: $text,
            configuration: RichTextConfiguration(
                placeholder: "Start writing…",
                keyboardToolbarItems: RichTextToolbarItem.defaultItems
            )
        )
    }
}
```

That's a working editor. The formatting buttons appear above the keyboard while typing.

`text` is an `NSAttributedString`: the text together with its formatting. It updates as the user types.

## Putting the toolbar somewhere else

You don't have to show the toolbar above the keyboard. You can place `RichTextToolbar` anywhere, for example on top of the editor:

```swift
struct NoteView: View {
    @State private var text = NSAttributedString()
    @StateObject private var context = RichTextContext()

    var body: some View {
        VStack(spacing: 0) {
            RichTextToolbar(context: context)
            Divider()
            RichTextEditor(text: $text, context: context)
        }
    }
}
```

The toolbar and the editor are separate views, so they need a way to talk to each other. That's what `RichTextContext` is for. Create one and give the same one to both:

- the editor tells the context what's under the cursor (is it bold? is it a list?), so the toolbar can highlight the right buttons;
- the toolbar asks the context to change the text (make it bold, start a list), and the context passes it to the editor.

The first screenshot above is built this way. Its code is in [`BoxedEditor.swift`](Example/MossTextEditorExample/Shared/BoxedEditor.swift), about 40 lines you can copy into your app.

## Choosing toolbar buttons

Pass the buttons you want, in order:

```swift
RichTextToolbar(context: context, items: [.bold, .italic, .divider, .bulletList, .undo, .redo])
```

The same list works for the keyboard toolbar through `keyboardToolbarItems`.

| Item | Button |
| --- | --- |
| `.bold`, `.italic`, `.underline`, `.strikethrough` | Text styles |
| `.title`, `.heading` | Paragraph styles. Tapping the active one turns the paragraph back into body text |
| `.bulletList`, `.numberedList` | Lists |
| `.undo`, `.redo` | Undo and redo |
| `.dismissKeyboard` | Hides the keyboard |
| `.divider` | A thin separator between groups |

`RichTextToolbarItem.defaultItems` has all of them.

When the buttons don't fit, the toolbar scrolls sideways. Undo, redo and dismiss keyboard stay pinned to the right edge so they are always reachable. To let them scroll with the rest, pass `pinsActions: false` to `RichTextToolbar`, or `keyboardToolbarPinsActions: false` to the configuration.

## Saving and loading

Turn the text into `Data` to store it in a file, a database or Core Data / SwiftData:

```swift
// Save
let data = try text.richTextData()

// Load
text = try NSAttributedString(richTextData: data)
```

Two formats are available:

| Format | Use it when |
| --- | --- |
| `.archive` (default) | You only read the data back in your own app. Keeps everything exactly |
| `.rtf` | Other apps should be able to open it, for example when exporting a file |

```swift
let rtf = try text.richTextData(format: .rtf)
text = try NSAttributedString(richTextData: rtf, format: .rtf)
```

Text colors are not saved, so saved text always follows light and dark mode.

For search or previews, use the plain text: `text.string`.

## Customizing

Everything about the editor's look and behavior is set with `RichTextConfiguration`. Pass only what you want to change:

```swift
RichTextEditor(
    text: $text,
    configuration: RichTextConfiguration(
        bodyFont: .systemFont(ofSize: 18),
        tintColor: .systemGreen,
        placeholder: "Dear diary…",
        autocorrects: true
    )
)
```

### All options

| Option | Default | Description |
| --- | --- | --- |
| **Text** | | |
| `bodyFont` | System 17 | Font of normal text. Bold and italic are derived from it |
| `titleFont` | System 28 | Font of title paragraphs. Titles are bold |
| `headingFont` | System 22 | Font of heading paragraphs. Headings are bold |
| `textColor` | `.label` | Color of the text |
| `tintColor` | none (uses the app's tint) | Color of the cursor, the selection and the active buttons of the keyboard toolbar |
| `lineSpacing` | `4` | Space between lines inside a paragraph |
| `paragraphSpacing` | `8` | Space after each paragraph |
| `listIndent` | `28` | How far list item text is indented from the bullet or number |
| **Layout** | | |
| `contentInsets` | 16 top/bottom, 12 left/right | Space between the edges of the editor and the text |
| `placeholder` | none | Text shown while the editor is empty |
| `placeholderColor` | `.placeholderText` | Color of the placeholder |
| `isScrollEnabled` | `true` | When `false`, the editor doesn't scroll and grows as tall as its text. Use it inside your own `ScrollView` or for chat-style inputs |
| `showsScrollIndicator` | `true` | Shows the scroll bar while scrolling |
| **Behavior** | | |
| `isEditable` | `true` | When `false`, the text can be read and selected but not changed |
| `keyboardDismissMode` | `.interactive` | How the keyboard hides when scrolling the text |
| `autocorrects` | `false` | Turns on the system's autocorrection |
| `autoformatsLists` | `true` | Typing `- `, `* ` or `1. ` at the start of a line starts a list |
| `pastesPlainText` | `true` | Pasted text takes the style at the cursor instead of keeping its original formatting |
| **Keyboard toolbar** | | |
| `keyboardToolbarItems` | `[]` (no toolbar) | Buttons shown above the keyboard. See [Choosing toolbar buttons](#choosing-toolbar-buttons) |
| `keyboardToolbarPinsActions` | `true` | Keeps undo, redo and dismiss keyboard pinned to the right edge of the keyboard toolbar |

## Recipes

Each recipe is a complete screen in the [example app](#example-app). Copy the file and make it yours.

<table>
<tr>
<td width="240"><img src="Docs/Images/boxed-light.png" width="240" alt="Boxed editor"></td>
<td>

### Boxed editor

The toolbar sits on top of the text inside a rounded box, like a form field.

```swift
VStack(spacing: 0) {
    RichTextToolbar(context: context)
    Divider()
    RichTextEditor(text: $text, context: context)
        .frame(height: 260)
}
.background(Color(.secondarySystemBackground),
            in: RoundedRectangle(cornerRadius: 16))
```

[`BoxedEditor.swift`](Example/MossTextEditorExample/Shared/BoxedEditor.swift)

</td>
</tr>
<tr>
<td width="240"><img src="Docs/Images/floating-light.png" width="240" alt="Floating toolbar"></td>
<td>

### Floating toolbar

A capsule that floats above the keyboard and only shows up while typing.

```swift
RichTextEditor(text: $text, context: context)
    .overlay(alignment: .bottom) {
        if context.isEditing {
            RichTextToolbar(context: context,
                            items: [.bold, .italic, .title, .bulletList])
                .background(.regularMaterial, in: Capsule())
                .shadow(radius: 12, y: 4)
                .padding()
        }
    }
```

[`FloatingToolbarExample.swift`](Example/MossTextEditorExample/Examples/FloatingToolbarExample.swift)

</td>
</tr>
<tr>
<td width="240"><img src="Docs/Images/composer-light.png" width="240" alt="Message composer"></td>
<td>

### Message composer

A chat input that grows with its text. Sent messages are shown with the same editor, read-only.

```swift
HStack(alignment: .bottom) {
    VStack(spacing: 0) {
        RichTextEditor(
            text: $draft,
            context: context,
            configuration: RichTextConfiguration(
                placeholder: "Message",
                isScrollEnabled: false
            )
        )
        if context.isEditing {
            RichTextToolbar(context: context,
                            items: [.bold, .italic, .bulletList])
        }
    }
    .background(Color(.secondarySystemBackground),
                in: RoundedRectangle(cornerRadius: 20))

    Button(action: send) {
        Image(systemName: "arrow.up.circle.fill")
    }
}
```

[`MessageComposerExample.swift`](Example/MossTextEditorExample/Examples/MessageComposerExample.swift)

</td>
</tr>
<tr>
<td width="240"><img src="Docs/Images/custom-light.png" width="240" alt="Custom style"></td>
<td>

### Your own look

Serif fonts, warm colors and roomy spacing turn the same editor into a paper notebook.

```swift
RichTextConfiguration(
    bodyFont: serif(19),
    titleFont: serif(30),
    headingFont: serif(23),
    tintColor: .systemBrown,
    lineSpacing: 6,
    paragraphSpacing: 12
)
```

[`CustomStyleExample.swift`](Example/MossTextEditorExample/Examples/CustomStyleExample.swift)

</td>
</tr>
</table>

## Advanced

### Building your own controls

You can skip `RichTextToolbar` and use your own buttons, menus or keyboard shortcuts. They all go through a `RichTextContext`:

```swift
struct NoteView: View {
    @State private var text = NSAttributedString()
    @StateObject private var context = RichTextContext()

    var body: some View {
        RichTextEditor(text: $text, context: context)
            .toolbar {
                Button {
                    context.toggle(.bold)
                } label: {
                    Image(systemName: "bold")
                }
                .foregroundStyle(context.isActive(.bold) ? .green : .primary)

                Menu("Style") {
                    Button("Title") { context.setBlockStyle(.title) }
                    Button("Heading") { context.setBlockStyle(.heading) }
                    Button("Body") { context.setBlockStyle(.body) }
                }
            }
    }
}
```

What the context tells you about the text at the cursor:

| Name | Description |
| --- | --- |
| `isActive(_:)` | Whether a text style is on where the cursor is. `context.isActive(.bold)` is `true` when the cursor is in bold text |
| `blockStyle` | The paragraph style where the cursor is: `.title`, `.heading` or `.body` |
| `listStyle` | The list the cursor is in: `.bullet`, `.numbered`, or `nil` outside a list |
| `isEditing` | `true` while the keyboard is up. Handy for showing controls only while typing |
| `canUndo`, `canRedo` | Whether there is something to undo or redo |

What you can ask it to do:

| Method | Description |
| --- | --- |
| `toggle(_:)` | Turns a text style on or off for the selection, or for the next typed text |
| `setBlockStyle(_:)` | Makes the selected paragraphs a title, heading or body text |
| `toggleList(_:)` | Turns the selected paragraphs into a list, or back into text |
| `undo()`, `redo()` | Undo and redo |
| `focus()` | Shows the keyboard |
| `dismissKeyboard()` | Hides the keyboard |

If you don't pass a context, the editor creates its own. You only need one when something outside the editor has to read or change the formatting.

For everything else, see [`RichTextContext.swift`](Sources/MossTextEditor/RichTextContext.swift).

## Example app

Open `MossTextEditor.xcworkspace` and run the **MossTextEditorExample** scheme. Each example is a single file you can read on its own:

| Example | Shows |
| --- | --- |
| [Boxed editor](Example/MossTextEditorExample/Examples/BoxedEditorExample.swift) | An editor in a rounded box with the toolbar on top, like a form field |
| [Custom style](Example/MossTextEditorExample/Examples/CustomStyleExample.swift) | Serif fonts, colors, spacing and a shorter toolbar |
| [Saving and loading](Example/MossTextEditorExample/Examples/PersistenceExample.swift) | Saving to a file and reading it back, to check that nothing gets lost |
| [Read-only display](Example/MossTextEditorExample/Examples/ReadOnlyExample.swift) | Showing formatted text on a detail screen and editing it in place |
| [Keyboard toolbar](Example/MossTextEditorExample/Examples/KeyboardToolbarExample.swift) | A full-screen editor with the toolbar above the keyboard |
| [Floating toolbar](Example/MossTextEditorExample/Examples/FloatingToolbarExample.swift) | A capsule toolbar floating above the keyboard while typing |
| [Message composer](Example/MossTextEditorExample/Examples/MessageComposerExample.swift) | A chat-style input that grows as you type, with a send button |
| [Custom controls](Example/MossTextEditorExample/Examples/CustomToolbarExample.swift) | Your own buttons and menus instead of the ready-made toolbar |

## License

MIT. See [LICENSE](LICENSE).
