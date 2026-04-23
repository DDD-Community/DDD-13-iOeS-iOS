import SwiftUI

@MainActor
enum SpotRegistrationAssembly {
    static func make(onRegistered: @escaping @MainActor (SpotId) -> Void) -> some View {
        let spotService: SpotServiceProtocol = AppContainer.shared.container.resolve(SpotServiceProtocol.self)!

        return SpotRegistrationView(
            viewModel: SpotRegistrationViewModel(spotService: spotService),
            onRegistered: onRegistered
        )
    }
}
