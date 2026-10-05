import MossTextEditor
import SwiftUI

/// Hides the keyboard toolbar and drives the editor from your own controls
/// through `RichTextContext`.
struct CustomToolbarExample: View {
    @State private var text = NSAttributedString()
    @StateObject private var context = RichTextContext()

    var body: some View {
        RichTextEditor(
            text: $text,
            context: context,
            configuration: RichTextConfiguration(
                placeholder: "Use the controls below…"
            )
        )
        .safeAreaInset(edge: .bottom) {
            formatBar
        }
        .navigationTitle("Custom controls")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var formatBar: some View {
        HStack(spacing: 12) {
            Menu {
                Picker("Paragraph", selection: blockStyle) {
                    Text("Title").tag(RichTextBlockStyle.title)
                    Text("Heading").tag(RichTextBlockStyle.heading)
                    Text("Body").tag(RichTextBlockStyle.body)
                }
            } label: {
                Label(blockStyleName, systemImage: "textformat.size")
                    .font(.subheadline.weight(.medium))
            }

            Divider().frame(height: 20)

            styleButton(.bold, "bold")
            styleButton(.italic, "italic")
            styleButton(.underline, "underline")

            Button {
                context.toggleList(.bullet)
            } label: {
                Image(systemName: "list.bullet")
            }
            .foregroundStyle(context.listStyle == .bullet ? Color.accentColor : .primary)

            Spacer()

            if context.isEditing {
                Button("Done") { context.dismissKeyboard() }
                    .fontWeight(.semibold)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(.bar)
    }

    private func styleButton(_ style: RichTextInlineStyle, _ systemImage: String) -> some View {
        Button {
            context.toggle(style)
        } label: {
            Image(systemName: systemImage)
                .frame(width: 32, height: 32)
                .background(
                    Circle().fill(context.isActive(style) ? Color.accentColor.opacity(0.2) : .clear)
                )
        }
        .foregroundStyle(context.isActive(style) ? Color.accentColor : .primary)
    }

    /// Selecting the current style again resets it to body, so set it directly.
    private var blockStyle: Binding<RichTextBlockStyle> {
        Binding(
            get: { context.blockStyle },
            set: { newValue in
                if newValue != context.blockStyle { context.setBlockStyle(newValue) }
            }
        )
    }

    private var blockStyleName: String {
        switch context.blockStyle {
        case .title: "Title"
        case .heading: "Heading"
        case .body: "Body"
        }
    }
}
