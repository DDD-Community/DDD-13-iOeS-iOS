import Foundation

protocol DIContainerProtocol: Sendable {
    func register<T>(_ type: T.Type, factory: @Sendable @escaping () -> T)
    func resolve<T>(_ type: T.Type) -> T?
}

enum DIContainerHolder: Sendable {
    @MainActor static var shared: (any DIContainerProtocol)?
}
