import Foundation

protocol GuestModeStore: Sendable {
    func hasEnteredAsGuest() -> Bool
    func markGuestEntry()
}

final class UserDefaultsGuestModeStore: GuestModeStore, @unchecked Sendable {
    private static let storageKey = "hasEnteredAsGuest"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func hasEnteredAsGuest() -> Bool {
        defaults.bool(forKey: Self.storageKey)
    }

    func markGuestEntry() {
        defaults.set(true, forKey: Self.storageKey)
    }
}

@MainActor
func getGuestModeStore() -> GuestModeStore {
    guard let store = DIContainerHolder.shared?.resolve(GuestModeStore.self) else {
        fatalError("GuestModeStore is not registered in DIContainer")
    }
    return store
}
