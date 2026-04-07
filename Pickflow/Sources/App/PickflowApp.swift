import SwiftUI

@main
struct PickflowApp: App {
    private let container = AppContainer.shared

    init() {
        DesignSystemFontRegistrar.registerAllCustomFonts()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
