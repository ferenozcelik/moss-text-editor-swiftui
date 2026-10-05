import SwiftUI

@main
struct ExampleApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ExampleList()
            }
        }
    }
}

struct ExampleList: View {
    var body: some View {
        List {
            Section("Examples") {
                NavigationLink("Boxed editor") { BoxedEditorExample() }
                NavigationLink("Custom style") { CustomStyleExample() }
                NavigationLink("Saving and loading") { PersistenceExample() }
                NavigationLink("Read-only display") { ReadOnlyExample() }
            }
            Section("Toolbar placement") {
                NavigationLink("Keyboard toolbar") { KeyboardToolbarExample() }
                NavigationLink("Floating toolbar") { FloatingToolbarExample() }
                NavigationLink("Message composer") { MessageComposerExample() }
                NavigationLink("Custom controls") { CustomToolbarExample() }
            }
        }
        .navigationTitle("MossTextEditor")
    }
}
