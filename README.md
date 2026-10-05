# MossTextEditor

A simple rich text editor for SwiftUI, backed by `UITextView`.

- **Inline styles:** bold, italic, underline, strikethrough
- **Paragraph styles:** title, heading, body
- **Lists:** bulleted and numbered. Return continues a list, Return on an empty item ends it, and `- `, `* ` or `1. ` at the start of a line starts one
- **Toolbar** that you can show above the keyboard, place anywhere (on top of a box, floating, in a composer) or replace with your own controls
- Undo and redo for typing, formatting and list edits
- Placeholder, dark mode, plain-text pasting

Requires iOS 16+.

## Installation

In Xcode, choose **File → Add Package Dependencies…** and enter:

```
https://github.com/ferenozcelik/moss-text-editor-swiftui
```

Or add it to `Package.swift`:

```swift
.package(url: "https://github.com/ferenozcelik/moss-text-editor-swiftui", from: "1.0.0")
```

## Usage

```swift
import MossTextEditor
import SwiftUI

struct NoteView: View {
    @State private var text = NSAttributedString()

    var body: some View {
        RichTextEditor(
            text: $text,
            configuration: RichTextConfiguration(keyboardToolbarItems: RichTextToolbarItem.defaultItems)
        )
    }
}
```

Without `keyboardToolbarItems` the editor shows no formatting controls, so you can place them yourself (see [Custom controls](#custom-controls)).

### Configuration

```swift
RichTextEditor(
    text: $text,
    configuration: RichTextConfiguration(
        bodyFont: .systemFont(ofSize: 17),
        titleFont: .systemFont(ofSize: 28),
        headingFont: .systemFont(ofSize: 22),
        tintColor: .systemGreen,
        placeholder: "Start writing…",
        autocorrects: true, // off by default
        keyboardToolbarItems: [.bold, .italic, .divider, .bulletList, .dismissKeyboard]
    )
)
```

Set `isScrollEnabled: false` to let the editor grow with its content inside your own `ScrollView`.
Set `showsScrollIndicator: false` to hide the scroll bar.

Undo, redo and dismiss keyboard are pinned to the trailing edge of the toolbar while the other items scroll. Pass `pinsActions: false` to `RichTextToolbar` (or `keyboardToolbarPinsActions: false` in the configuration) to let them scroll with the rest.

### Custom controls

`RichTextContext` connects an editor to the controls that format it. The editor writes the state at the cursor into it (is the text bold, which paragraph style, which list…), and the controls call its actions to change the text.
Create one, pass the same instance to the editor and to `RichTextToolbar` or your own buttons:

```swift
@StateObject private var context = RichTextContext()

var body: some View {
    VStack {
        RichTextEditor(text: $text, context: context)
        RichTextToolbar(context: context, items: [.bold, .italic, .bulletList])
        Button("Bold") { context.toggle(.bold) }
            .foregroundStyle(context.isActive(.bold) ? .green : .primary)
    }
}
```

`RichTextContext` exposes `activeStyles`, `blockStyle`, `listStyle`, `selectedRange`, `isEditing`, `canUndo` and `canRedo`.
Its actions are `toggle(_:)`, `setBlockStyle(_:)`, `toggleList(_:)`, `undo()`, `redo()`, `focus()` and `dismissKeyboard()`.

### Saving

The text is a regular `NSAttributedString`. To store it, encode it to `Data`:

```swift
let data = try text.richTextData()                    // keyed archive, lossless
let restored = try NSAttributedString(richTextData: data)

let rtf = try text.richTextData(format: .rtf)         // readable by other apps
let fromRTF = try NSAttributedString(richTextData: rtf, format: .rtf)
```

Text colors are not stored, so the text follows light and dark mode.
Use `text.string` for a plain-text version, for example for search.

## How formatting is stored

- **Title and heading** are font sizes. When text is loaded, every font is mapped to the closest configured font by size, keeping bold and italic.
- **List items** are text prefixes (`•\t`, `1.\t`) with a hanging indent. Lists stay readable in plain text and survive RTF.

## Examples

Open `MossTextEditor.xcworkspace` and run the `MossTextEditorExample` scheme. Each example is a single file in [`Example/MossTextEditorExample/Examples`](Example/MossTextEditorExample/Examples):

| Example | Shows |
| --- | --- |
| [Boxed editor](Example/MossTextEditorExample/Examples/BoxedEditorExample.swift) | A rounded box with the toolbar on top of the text, like a form field |
| [Custom style](Example/MossTextEditorExample/Examples/CustomStyleExample.swift) | Serif fonts, colors, spacing and a shorter toolbar |
| [Saving and loading](Example/MossTextEditorExample/Examples/PersistenceExample.swift) | Saving as archive or RTF, reading it back and showing the decoded copy next to the original |
| [Read-only display](Example/MossTextEditorExample/Examples/ReadOnlyExample.swift) | Showing formatted text on a detail screen and editing it in place |
| [Keyboard toolbar](Example/MossTextEditorExample/Examples/KeyboardToolbarExample.swift) | A full-screen editor with the default toolbar above the keyboard |
| [Floating toolbar](Example/MossTextEditorExample/Examples/FloatingToolbarExample.swift) | A capsule toolbar floating above the keyboard while editing |
| [Message composer](Example/MossTextEditorExample/Examples/MessageComposerExample.swift) | A chat-style growing input with a compact toolbar and a send button |
| [Custom controls](Example/MossTextEditorExample/Examples/CustomToolbarExample.swift) | Your own buttons and menus driven by `RichTextContext` |

The box used by the first examples is [`BoxedEditor`](Example/MossTextEditorExample/Shared/BoxedEditor.swift), about 40 lines you can copy into your app.

## License

MIT. See [LICENSE](LICENSE).
