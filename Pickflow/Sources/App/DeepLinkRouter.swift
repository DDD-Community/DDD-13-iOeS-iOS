import Foundation

@MainActor
final class DeepLinkRouter: ObservableObject {
    @Published var pendingSpotId: Int64?
}
