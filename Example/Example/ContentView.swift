import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ControlsTab()
                .tabItem {
                    Label("Controls", systemImage: "slider.horizontal.3")
                }
                .accessibilityIdentifier("tab_controls")

            InputTab()
                .tabItem {
                    Label("Input", systemImage: "keyboard")
                }
                .accessibilityIdentifier("tab_input")

            ListsTab()
                .tabItem {
                    Label("Lists", systemImage: "list.bullet")
                }
                .accessibilityIdentifier("tab_lists")

            GesturesTab()
                .tabItem {
                    Label("Gestures", systemImage: "hand.tap")
                }
                .accessibilityIdentifier("tab_gestures")
        }
        .accessibilityIdentifier("main_tab_view")
    }
}

#Preview {
    ContentView()
}
