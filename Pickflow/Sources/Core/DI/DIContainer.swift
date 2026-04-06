import Swinject

extension DIScope {
    var objectScope: ObjectScope {
        switch self {
        case .transient: .transient
        case .container: .container
        case .graph: .graph
        }
    }
}

final class DIContainer: DIContainerProtocol, @unchecked Sendable {
    private let container = Container()

    func register<T>(_ type: T.Type, scope: DIScope = .container, factory: @Sendable @escaping () -> T) {
        container.register(type) { _ in factory() }.inObjectScope(scope.objectScope)
    }

    func resolve<T>(_ type: T.Type) -> T? {
        container.resolve(type)
    }
}
