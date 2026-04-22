import SwiftUI

@MainActor
enum SpotRegistrationAssembly {
    static func make() -> some View {
        let spotService: SpotServiceProtocol = AppContainer.shared.container.resolve(SpotServiceProtocol.self)!

        return SpotRegistrationView(
            viewModel: SpotRegistrationViewModel(spotService: spotService)
        )
    }
}
