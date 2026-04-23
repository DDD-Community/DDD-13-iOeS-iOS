import SwiftUI

struct ContentView: View {
    @State private var path: [ContentRoute] = []
    @State private var pendingRegisteredSpotId: SpotId?
    @State private var presentedSpotId: SpotId?

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 16) {
                Text("Pickflow")
                    .pretendard(.display(.medium))

                Button("스팟 등록 열기") {
                    path.append(.spotRegistration)
                }
                .pretendard(.body(.large(.bold)))
                .buttonStyle(.plain)
            }
            .navigationDestination(for: ContentRoute.self) { route in
                switch route {
                case .spotRegistration:
                    SpotRegistrationAssembly.make { spotId in
                        pendingRegisteredSpotId = spotId
                        path.removeLast()
                    }
                }
            }
        }
        .onChange(of: path, initial: false) { _, newValue in
            guard newValue.isEmpty, let pendingRegisteredSpotId else { return }
            presentedSpotId = pendingRegisteredSpotId
            self.pendingRegisteredSpotId = nil
        }
        .fullScreenCover(item: $presentedSpotId) { spotId in
            NavigationStack {
                SpotDetailPlaceholderView(spotId: spotId)
            }
        }
    }
}

#Preview {
    ContentView()
}

private enum ContentRoute: Hashable {
    case spotRegistration
}
