import MossTextEditor
import SwiftUI

/// An editor inside a rounded box with the toolbar on top of it, like a form
/// field. See `BoxedEditor` for how the box is built.
struct BoxedEditorExample: View {
    @State private var text = NSAttributedString()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Today's entry")
                    .font(.headline)

                BoxedEditor(
                    text: $text,
                    configuration: RichTextConfiguration(
                        contentInsets: UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8),
                        placeholder: "What happened today?"
                    )
                )

                Text("\(text.string.count) characters")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Boxed editor")
        .navigationBarTitleDisplayMode(.inline)
    }
}
