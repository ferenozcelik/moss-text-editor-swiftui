import MossTextEditor
import SwiftUI

/// Serif fonts, custom colors and spacing, and a shorter toolbar.
struct CustomStyleExample: View {
    @State private var text = SampleText.journal

    private static func serif(_ size: CGFloat) -> UIFont {
        let descriptor = UIFont.systemFont(ofSize: size).fontDescriptor.withDesign(.serif)
        return descriptor.map { UIFont(descriptor: $0, size: size) } ?? .systemFont(ofSize: size)
    }

    private let configuration = RichTextConfiguration(
        bodyFont: serif(19),
        titleFont: serif(30),
        headingFont: serif(23),
        textColor: UIColor { $0.userInterfaceStyle == .dark ? .white : UIColor(red: 0.2, green: 0.17, blue: 0.13, alpha: 1) },
        tintColor: .systemBrown,
        lineSpacing: 6,
        paragraphSpacing: 12,
        contentInsets: UIEdgeInsets(top: 16, left: 14, bottom: 16, right: 14),
        placeholder: "Dear diary…",
        showsScrollIndicator: false
    )

    private let paper = Color(UIColor {
        $0.userInterfaceStyle == .dark ? UIColor(white: 0.12, alpha: 1) : UIColor(red: 0.98, green: 0.96, blue: 0.91, alpha: 1)
    })

    var body: some View {
        ScrollView {
            BoxedEditor(
                text: $text,
                configuration: configuration,
                toolbarItems: [.bold, .italic, .divider, .heading, .bulletList, .undo, .redo],
                height: 460,
                background: paper
            )
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Custom style")
        .navigationBarTitleDisplayMode(.inline)
    }
}
