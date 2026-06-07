import Foundation
@testable import Pickflow

final class MockAppVersionService: AppVersionServiceProtocol, @unchecked Sendable {
    var fetchResult: Result<AppVersionPolicy, any Error> = .success(.fixture())
    private(set) var fetchCallCount = 0

    func fetchIOSVersionPolicy() async throws -> AppVersionPolicy {
        fetchCallCount += 1
        return try fetchResult.get()
    }
}

extension AppVersionPolicy {
    static func fixture(
        minimumVersion: String = "1.0.0",
        latestVersion: String = "1.0.0",
        forceUpdate: Bool = false,
        storeUrl: String = "https://apps.apple.com/app/id000000000",
        supportEmail: String? = nil,
        termsPolicies: [TermsPolicy]? = nil
    ) -> AppVersionPolicy {
        AppVersionPolicy(
            minimumVersion: minimumVersion,
            latestVersion: latestVersion,
            forceUpdate: forceUpdate,
            storeUrl: storeUrl,
            supportEmail: supportEmail,
            termsPolicies: termsPolicies
        )
    }
}
