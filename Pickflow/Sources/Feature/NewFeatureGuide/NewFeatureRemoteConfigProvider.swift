import Foundation
import FirebaseCore
import FirebaseRemoteConfig

protocol NewFeatureRemoteConfigProvider: Sendable {
    func fetchFeatureConfig() async throws -> NewFeatureRemoteConfig
}

final class FirebaseNewFeatureRemoteConfigProvider: NewFeatureRemoteConfigProvider, @unchecked Sendable {
    static let remoteConfigKey = "new_feature_flags"

    private var remoteConfig: RemoteConfig?

    init(remoteConfig: RemoteConfig? = nil) {
        self.remoteConfig = remoteConfig
        configureRemoteConfigIfNeeded()
    }

    func fetchFeatureConfig() async throws -> NewFeatureRemoteConfig {
        guard FirebaseApp.app() != nil else {
            throw NewFeatureRemoteConfigProviderError.firebaseNotConfigured
        }
        let remoteConfig = self.remoteConfig ?? RemoteConfig.remoteConfig()
        self.remoteConfig = remoteConfig
        configure(remoteConfig)
        _ = try await remoteConfig.fetchAndActivate()
        let data = remoteConfig.configValue(forKey: Self.remoteConfigKey).dataValue
        return try JSONDecoder().decode(NewFeatureRemoteConfig.self, from: data)
    }

    private func configureRemoteConfigIfNeeded() {
        guard let remoteConfig else { return }
        configure(remoteConfig)
    }

    private func configure(_ remoteConfig: RemoteConfig) {
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 60 * 60
        remoteConfig.configSettings = settings
    }
}

enum NewFeatureRemoteConfigProviderError: Error {
    case firebaseNotConfigured
}

struct NewFeatureRemoteConfig: Codable, Sendable, Equatable {
    let serverTime: Int64
    let features: [NewFeatureRemoteConfigFeature]

    func feature(forKey key: String) -> NewFeatureRemoteConfigFeature? {
        features.first { $0.key == key }
    }
}

struct NewFeatureRemoteConfigFeature: Codable, Sendable, Equatable {
    let key: String
    let startAt: Int64?
    let endAt: Int64?
    let durationDays: Int?
}
