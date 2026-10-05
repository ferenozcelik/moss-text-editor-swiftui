import MossTextEditor
import SwiftUI

/// Shows saved text read-only, for example on a detail screen, and switches
/// to editing in place.
struct ReadOnlyExample: View {
    @State private var text = SampleText.journal
    @State private var isEditing = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text(Date.now, style: .date)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                RichTextEditor(
                    text: $text,
                    configuration: RichTextConfiguration(
                        contentInsets: UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12),
                        isScrollEnabled: false,
                        isEditable: isEditing,
                        keyboardToolbarItems: RichTextToolbarItem.defaultItems
                    )
                )
            }
            .padding(.vertical)
        }
        .navigationTitle("Read-only display")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button(isEditing ? "Done" : "Edit") { isEditing.toggle() }
                .fontWeight(isEditing ? .semibold : .regular)
        }
    }
}
