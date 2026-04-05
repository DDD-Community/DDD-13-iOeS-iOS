import Foundation

enum DIScope: Sendable {
    case transient
    case container
    case graph
}

protocol DIContainerProtocol: Sendable {
    func register<T>(_ type: T.Type, scope: DIScope, factory: @Sendable @escaping () -> T)
    func resolve<T>(_ type: T.Type) -> T?
}

enum DIContainerHolder: Sendable {
    @MainActor static var shared: (any DIContainerProtocol)?
}
