import Foundation
@testable import Pickflow

final class FakeNewFeatureGuideStore: NewFeatureGuideStore, @unchecked Sendable {
    var shouldShowV2UpdateModalValue = false
    var shouldShowSpotOpenGuideValue = false
    var shouldShowNewThemeIndicatorsValue = false
    private(set) var didMarkV2UpdateModalSeen = false
    private(set) var markedSpotOpenGuideUserKeys: [String] = []

    func shouldShowV2UpdateModal(now _: Date) -> Bool {
        shouldShowV2UpdateModalValue
    }

    func markV2UpdateModalSeen() {
        didMarkV2UpdateModalSeen = true
    }

    func shouldShowSpotOpenGuide(userKey _: String, now _: Date) -> Bool {
        shouldShowSpotOpenGuideValue
    }

    func markSpotOpenGuideSeen(userKey: String) {
        markedSpotOpenGuideUserKeys.append(userKey)
    }

    func shouldShowNewThemeIndicators(now _: Date) -> Bool {
        shouldShowNewThemeIndicatorsValue
    }
}
