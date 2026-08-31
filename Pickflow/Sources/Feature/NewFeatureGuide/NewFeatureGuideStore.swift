import CryptoKit
import Foundation

protocol NewFeatureGuideStore: Sendable {
    func shouldShowV2UpdateModal(now: Date) -> Bool
    func markV2UpdateModalSeen()
    func shouldShowSpotOpenGuide(userKey: String, now: Date) -> Bool
    func markSpotOpenGuideSeen(userKey: String)
    func shouldShowNewThemeIndicators(now: Date) -> Bool
}

final class UserDefaultsNewFeatureGuideStore: NewFeatureGuideStore, @unchecked Sendable {
    private static let baseKey = "newFeatureGuide.v2"
    private static let exposureDuration: TimeInterval = 14 * 24 * 60 * 60

    private let defaults: UserDefaults
    private let appVersionProvider: @Sendable () -> String

    init(
        defaults: UserDefaults = .standard,
        appVersionProvider: @escaping @Sendable () -> String = { Bundle.main.appVersion }
    ) {
        self.defaults = defaults
        self.appVersionProvider = appVersionProvider
    }

    func shouldShowV2UpdateModal(now: Date = Date()) -> Bool {
        isWithinExposurePeriod(now: now) && !defaults.bool(forKey: v2UpdateModalSeenKey)
    }

    func markV2UpdateModalSeen() {
        defaults.set(true, forKey: v2UpdateModalSeenKey)
    }

    func shouldShowSpotOpenGuide(userKey: String, now: Date = Date()) -> Bool {
        isWithinExposurePeriod(now: now) && !defaults.bool(forKey: spotOpenGuideSeenKey(userKey: userKey))
    }

    func markSpotOpenGuideSeen(userKey: String) {
        defaults.set(true, forKey: spotOpenGuideSeenKey(userKey: userKey))
    }

    func shouldShowNewThemeIndicators(now: Date = Date()) -> Bool {
        isWithinExposurePeriod(now: now)
    }

    private func isWithinExposurePeriod(now: Date) -> Bool {
        let startDate = campaignStartDate(now: now)
        return now.timeIntervalSince(startDate) < Self.exposureDuration
    }

    private func campaignStartDate(now: Date) -> Date {
        let key = campaignStartDateKey
        if let stored = defaults.object(forKey: key) as? Date {
            return stored
        }
        defaults.set(now, forKey: key)
        return now
    }

    private var version: String {
        let version = appVersionProvider()
        return version.isEmpty ? "unknown" : version
    }

    private var campaignStartDateKey: String {
        "\(Self.baseKey).campaignStartDate.\(version)"
    }

    private var v2UpdateModalSeenKey: String {
        "\(Self.baseKey).v2UpdateModalSeen.\(version)"
    }

    private func spotOpenGuideSeenKey(userKey: String) -> String {
        "\(Self.baseKey).spotOpenGuideSeen.\(version).\(userKey)"
    }
}

extension AuthToken {
    var newFeatureGuideUserKey: String {
        if let userId, !userId.isEmpty {
            return "user-\(userId)"
        }
        let rawValue = "\(accessToken).\(refreshToken)"
        let digest = SHA256.hash(data: Data(rawValue.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

@MainActor
func getNewFeatureGuideStore() -> NewFeatureGuideStore {
    guard let store = DIContainerHolder.shared?.resolve(NewFeatureGuideStore.self) else {
        fatalError("NewFeatureGuideStore is not registered in DIContainer")
    }
    return store
}
