import SwiftUI

@main
struct TrueAuthApp: App {
    @StateObject private var store = ProfileStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 380, minHeight: 300)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 420, height: 500)
    }
}
