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
        let status = try await remoteConfig.fetchAndActivate()
        let configValue = remoteConfig.configValue(forKey: Self.remoteConfigKey)
        let data = configValue.dataValue
        debugLog("fetchAndActivate status=\(status.rawValue), source=\(configValue.source.rawValue)")
        if let rawValue = String(data: data, encoding: .utf8) {
            debugLog("raw \(Self.remoteConfigKey)=\(rawValue)")
        }
        return try JSONDecoder().decode(NewFeatureRemoteConfig.self, from: data)
    }

    private func configureRemoteConfigIfNeeded() {
        guard let remoteConfig else { return }
        configure(remoteConfig)
    }

    private func configure(_ remoteConfig: RemoteConfig) {
        let settings = RemoteConfigSettings()
        #if DEBUG
        settings.minimumFetchInterval = 0
        #else
        settings.minimumFetchInterval = 60 * 60
        #endif
        remoteConfig.configSettings = settings
    }

    private func debugLog(_ message: String) {
        #if DEBUG
        print("[NewFeatureRemoteConfig] \(message)")
        #endif
    }
}

enum NewFeatureRemoteConfigProviderError: Error {
    case firebaseNotConfigured
}

struct NewFeatureRemoteConfig: Codable, Sendable, Equatable {
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
