import MossTextEditor
import SwiftUI

/// A full-screen editor with the default toolbar above the keyboard.
struct KeyboardToolbarExample: View {
    @State private var text = SampleText.journal

    var body: some View {
        RichTextEditor(
            text: $text,
            configuration: RichTextConfiguration(
                placeholder: "Start writing…",
                keyboardToolbarItems: RichTextToolbarItem.defaultItems
            )
        )
        .navigationTitle("Keyboard toolbar")
        .navigationBarTitleDisplayMode(.inline)
    }
}
