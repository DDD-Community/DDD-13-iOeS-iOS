import CryptoKit
import Foundation

protocol NewFeatureGuideStore: Sendable {
    func refreshFeatureConfig() async
    func shouldShowV2UpdateModal(now: Date) -> Bool
    func markV2UpdateModalSeen()
    func shouldShowSpotOpenGuide(userKey: String, now: Date) -> Bool
    func markSpotOpenGuideSeen(userKey: String)
    func shouldShowNewThemeIndicators() -> Bool
}

final class UserDefaultsNewFeatureGuideStore: NewFeatureGuideStore, @unchecked Sendable {
    private static let baseKey = "newFeatureGuide.v2"
    private static let v2UpdateModalFeatureKey = "v2_update_modal"
    private static let spotOpenGuideFeatureKey = "spot_open_guide"
    private static let newThemeIndicatorFeatureKey = "home_new_badge"

    private let defaults: UserDefaults
    private let appVersionProvider: @Sendable () -> String
    private let remoteConfigProvider: (any NewFeatureRemoteConfigProvider)?
    private let remoteConfigFallback: NewFeatureRemoteConfig?

    init(
        defaults: UserDefaults = .standard,
        appVersionProvider: @escaping @Sendable () -> String = { Bundle.main.appVersion },
        remoteConfigProvider: (any NewFeatureRemoteConfigProvider)? = nil,
        remoteConfigFallback: NewFeatureRemoteConfig? = nil
    ) {
        self.defaults = defaults
        self.appVersionProvider = appVersionProvider
        self.remoteConfigProvider = remoteConfigProvider
        self.remoteConfigFallback = remoteConfigFallback
    }

    func refreshFeatureConfig() async {
        guard let remoteConfigProvider else { return }
        guard let config = try? await remoteConfigProvider.fetchFeatureConfig() else { return }
        saveRemoteConfig(config)
    }

    func shouldShowV2UpdateModal(now: Date = Date()) -> Bool {
        isFeatureActive(featureKey: Self.v2UpdateModalFeatureKey)
            && !defaults.bool(forKey: v2UpdateModalSeenKey)
    }

    func markV2UpdateModalSeen() {
        defaults.set(true, forKey: v2UpdateModalSeenKey)
    }

    func shouldShowSpotOpenGuide(userKey: String, now: Date = Date()) -> Bool {
        isFeatureActive(featureKey: Self.spotOpenGuideFeatureKey, audienceKey: userKey)
            && !defaults.bool(forKey: spotOpenGuideSeenKey(userKey: userKey))
    }

    func markSpotOpenGuideSeen(userKey: String) {
        defaults.set(true, forKey: spotOpenGuideSeenKey(userKey: userKey))
    }

    func shouldShowNewThemeIndicators() -> Bool {
        isFeatureActive(featureKey: Self.newThemeIndicatorFeatureKey)
    }

    private func isFeatureActive(featureKey: String, audienceKey: String? = nil) -> Bool {
        guard let config = currentRemoteConfig,
              let feature = config.feature(forKey: featureKey)
        else {
            return false
        }
        return isFeatureActive(feature, serverTime: config.serverTime, audienceKey: audienceKey)
    }

    private var version: String {
        let version = appVersionProvider()
        return version.isEmpty ? "unknown" : version
    }

    private var v2UpdateModalSeenKey: String {
        "\(Self.baseKey).v2UpdateModalSeen.\(version)"
    }

    private func spotOpenGuideSeenKey(userKey: String) -> String {
        "\(Self.baseKey).spotOpenGuideSeen.\(version).\(userKey)"
    }

    private var currentRemoteConfig: NewFeatureRemoteConfig? {
        if let data = defaults.data(forKey: remoteConfigCacheKey),
           let config = try? JSONDecoder().decode(NewFeatureRemoteConfig.self, from: data) {
            return config
        }
        return remoteConfigFallback
    }

    private func saveRemoteConfig(_ config: NewFeatureRemoteConfig) {
        guard let data = try? JSONEncoder().encode(config) else { return }
        defaults.set(data, forKey: remoteConfigCacheKey)
    }

    private func isFeatureActive(
        _ feature: NewFeatureRemoteConfigFeature,
        serverTime: Int64,
        audienceKey: String?
    ) -> Bool {
        if let startAt = feature.startAt {
            return isLaunchBasedFeatureActive(feature, startAt: startAt, serverTime: serverTime)
        }

        let firstSeenAt = firstSeenAtForUserBasedFeature(
            featureKey: feature.key,
            audienceKey: audienceKey,
            serverTime: serverTime
        )
        guard let durationDays = feature.durationDays else { return false }
        return serverTime - firstSeenAt < milliseconds(days: durationDays)
    }

    private func isLaunchBasedFeatureActive(
        _ feature: NewFeatureRemoteConfigFeature,
        startAt: Int64,
        serverTime: Int64
    ) -> Bool {
        let endAt = feature.endAt ?? feature.durationDays.map { startAt + milliseconds(days: $0) }
        guard let endAt else { return false }
        return startAt <= serverTime && serverTime < endAt
    }

    private func firstSeenAtForUserBasedFeature(
        featureKey: String,
        audienceKey: String?,
        serverTime: Int64
    ) -> Int64 {
        let key = firstSeenAtKey(featureKey: featureKey, audienceKey: audienceKey)
        if defaults.object(forKey: key) != nil {
            return Int64(defaults.double(forKey: key))
        }
        defaults.set(Double(serverTime), forKey: key)
        return serverTime
    }

    private func milliseconds(days: Int) -> Int64 {
        Int64(days) * 24 * 60 * 60 * 1000
    }

    private var remoteConfigCacheKey: String {
        "\(Self.baseKey).remoteConfig.\(version)"
    }

    private func firstSeenAtKey(featureKey: String, audienceKey: String?) -> String {
        let audience = audienceKey ?? "device"
        return "\(Self.baseKey).firstSeenAt.\(version).\(featureKey).\(audience)"
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
