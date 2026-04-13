import SwiftUI

@main
struct PickflowApp: App {
    private let container = AppContainer.shared

    init() {
        DesignSystemFontRegister.registerAllCustomFonts()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
