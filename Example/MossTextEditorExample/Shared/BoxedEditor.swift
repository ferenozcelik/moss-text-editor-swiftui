import MossTextEditor
import SwiftUI

/// An editor in a rounded box with the toolbar on top, used by most examples.
/// Copy it into your app and adjust it to your design.
struct BoxedEditor: View {
    @Binding var text: NSAttributedString
    var configuration = RichTextConfiguration(
        contentInsets: UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
    )
    var toolbarItems: [RichTextToolbarItem] = [
        .bold, .italic, .underline, .strikethrough, .divider,
        .title, .heading, .divider,
        .bulletList, .numberedList,
        .undo, .redo,
    ]
    /// Keeps undo and redo visible at the trailing edge of the toolbar.
    var pinsActions = true
    var height: CGFloat = 260
    var background = Color(.secondarySystemBackground)

    @StateObject private var context = RichTextContext()

    private var accent: Color {
        configuration.tintColor.map(Color.init(uiColor:)) ?? .accentColor
    }

    var body: some View {
        VStack(spacing: 0) {
            RichTextToolbar(context: context, items: toolbarItems, pinsActions: pinsActions)
            Divider()
            RichTextEditor(text: $text, context: context, configuration: configuration)
                .frame(height: height)
        }
        .tint(accent)
        .background(background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color(.separator), lineWidth: 1)
        }
    }
}
