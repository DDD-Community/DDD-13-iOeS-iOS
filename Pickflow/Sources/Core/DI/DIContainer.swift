import Swinject

final class DIContainer: DIContainerProtocol, @unchecked Sendable {
    private let container = Container()

    func register<T>(_ type: T.Type, factory: @Sendable @escaping () -> T) {
        container.register(type) { _ in factory() }
    }

    func resolve<T>(_ type: T.Type) -> T? {
        container.resolve(type)
    }
}
