import SwiftUI

@main
struct SATApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if os(macOS)
        .defaultSize(width: 980, height: 680)
        #endif

    }
}

