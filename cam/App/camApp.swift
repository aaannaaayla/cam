import SwiftUI

@main
struct camApp: App {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var libraryService = PhotoLibraryService.shared

    init() {
        FontLoader.shared.loadBundledFonts()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(subscriptionManager)
                .environmentObject(libraryService)
                .preferredColorScheme(.dark)
        }
    }
}
