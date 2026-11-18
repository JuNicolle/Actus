import SwiftUI

@main
struct ActusApp: App {
    @State private var store = NewsStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
        }
    }
}
