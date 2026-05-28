import Combine
import SwiftUI

@MainActor
final class APIErrorHandler: ObservableObject {
    @Published var current: APIError?
    private var cancellable: AnyCancellable?

    init() {
        cancellable = NotificationCenter.default
            .publisher(for: .apiError)
            .compactMap { $0.object as? APIError }
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.current = $0 }
    }

    func dismiss() { current = nil }
}

extension View {
    func apiErrorAlert(_ handler: APIErrorHandler) -> some View {
        modifier(APIErrorAlertModifier(handler: handler))
    }
}

private struct APIErrorAlertModifier: ViewModifier {
    @ObservedObject var handler: APIErrorHandler

    func body(content: Content) -> some View {
        content.alert(
            "오류",
            isPresented: Binding(
                get: { handler.current != nil },
                set: { if !$0 { handler.dismiss() } }
            ),
            presenting: handler.current
        ) { _ in
            Button("확인", role: .cancel) { handler.dismiss() }
        } message: { error in
            Text(error.message)
        }
    }
}
