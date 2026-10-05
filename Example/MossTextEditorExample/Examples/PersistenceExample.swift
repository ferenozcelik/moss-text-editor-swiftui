import MossTextEditor
import SwiftUI

/// Saves the text with `richTextData(format:)`, reads it back from disk and shows
/// the decoded copy under the editor, so you can check that nothing is lost.
/// The same `Data` can go into Core Data, SwiftData, CloudKit or a server.
struct PersistenceExample: View {
    @State private var text = SampleText.journal
    @State private var loadedText: NSAttributedString?
    @State private var format = RichTextDataFormat.archive
    @State private var status = ""

    private var fileURL: URL {
        URL.documentsDirectory.appending(path: format == .archive ? "note.archive" : "note.rtf")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Picker("Format", selection: $format) {
                    Text("Archive").tag(RichTextDataFormat.archive)
                    Text("RTF").tag(RichTextDataFormat.rtf)
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading, spacing: 6) {
                    sectionTitle("Editor")
                    BoxedEditor(text: $text)
                }

                HStack {
                    Button("Save", action: save)
                        .buttonStyle(.borderedProminent)
                    Button("Load", action: load)
                        .buttonStyle(.bordered)
                    Spacer()
                    Text(status)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                section("Loaded from disk") {
                    if let loadedText {
                        RichTextEditor(
                            text: .constant(loadedText),
                            configuration: RichTextConfiguration(isScrollEnabled: false, isEditable: false)
                        )
                    } else {
                        Text("Save, then load to see the decoded text here.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, minHeight: 80)
                    }
                }
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Saving and loading")
        .navigationBarTitleDisplayMode(.inline)
        // Shows what an earlier launch saved.
        .onAppear(perform: load)
        .onChange(of: format) { _ in load() }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionTitle(title)
            content()
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func save() {
        do {
            let data = try text.richTextData(format: format)
            try data.write(to: fileURL, options: .atomic)
            status = "Saved \(data.count) bytes"
        } catch {
            status = "Save failed: \(error.localizedDescription)"
        }
    }

    private func load() {
        do {
            let data = try Data(contentsOf: fileURL)
            loadedText = try NSAttributedString(richTextData: data, format: format)
            status = "Loaded \(data.count) bytes"
        } catch {
            loadedText = nil
            status = "Nothing saved yet"
        }
    }
}
