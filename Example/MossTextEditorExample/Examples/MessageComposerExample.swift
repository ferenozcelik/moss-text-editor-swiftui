import MossTextEditor
import SwiftUI

/// A chat-style composer at the bottom of the screen: a box that grows with its
/// text, a compact toolbar under it and a send button.
struct MessageComposerExample: View {
    @State private var messages: [NSAttributedString] = []
    @State private var draft = NSAttributedString()
    @StateObject private var context = RichTextContext()

    var body: some View {
        ScrollView {
            VStack(alignment: .trailing, spacing: 8) {
                ForEach(messages.indices, id: \.self) { index in
                    // A non-editable editor displays the formatted message.
                    RichTextEditor(
                        text: .constant(messages[index]),
                        configuration: RichTextConfiguration(
                            textColor: .white,
                            paragraphSpacing: 4,
                            contentInsets: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8),
                            isScrollEnabled: false,
                            isEditable: false
                        )
                    )
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .padding(.leading, 60)
                }
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            composer
        }
        .navigationTitle("Message composer")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var composer: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(alignment: .bottom, spacing: 8) {
                VStack(spacing: 0) {
                    RichTextEditor(
                        text: $draft,
                        context: context,
                        configuration: RichTextConfiguration(
                            paragraphSpacing: 4,
                            contentInsets: UIEdgeInsets(top: 10, left: 8, bottom: 6, right: 8),
                            placeholder: "Message",
                            isScrollEnabled: false
                        )
                    )
                    if context.isEditing {
                        RichTextToolbar(context: context, items: [.bold, .italic, .strikethrough, .bulletList])
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .transition(.opacity)
                    }
                }
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .animation(.easeInOut(duration: 0.2), value: context.isEditing)

                Button(action: send) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 34))
                }
                .disabled(draft.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(.bar)
    }

    private func send() {
        messages.append(draft)
        draft = NSAttributedString()
    }
}
