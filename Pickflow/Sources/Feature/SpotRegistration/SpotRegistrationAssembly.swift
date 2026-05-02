import SwiftUI

@MainActor
enum SpotRegistrationAssembly {
    static func make(onRegistered: @escaping @MainActor (SpotId) -> Void) -> some View {
        let spotService = getSpotService()

        return SpotRegistrationView(
            viewModel: SpotRegistrationViewModel(spotService: spotService),
            onRegistered: onRegistered
        )
    }
}
