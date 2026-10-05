import MossTextEditor
import SwiftUI

/// A full-screen editor with a floating capsule toolbar that shows up while
/// editing and sits right above the keyboard.
struct FloatingToolbarExample: View {
    @State private var text = SampleText.journal
    @StateObject private var context = RichTextContext()

    var body: some View {
        RichTextEditor(
            text: $text,
            context: context,
            configuration: RichTextConfiguration(
                // Leaves room so the last lines can scroll above the toolbar.
                contentInsets: UIEdgeInsets(top: 16, left: 12, bottom: 88, right: 12)
            )
        )
        .overlay(alignment: .bottom) {
            if context.isEditing {
                RichTextToolbar(context: context, items: [.bold, .italic, .underline, .title, .heading, .bulletList, .dismissKeyboard])
                    .padding(.horizontal, 4)
                    .background(.regularMaterial, in: Capsule())
                    .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: context.isEditing)
        .navigationTitle("Floating toolbar")
        .navigationBarTitleDisplayMode(.inline)
    }
}
