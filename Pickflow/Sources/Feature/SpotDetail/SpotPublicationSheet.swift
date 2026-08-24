import Foundation

/// 스팟 상세에서 뜨는 공개 상태 확인 바텀시트. 한 번에 하나만 열린다.
enum SpotPublicationSheet: Equatable, Identifiable {
    /// "MY 스팟을 오픈할까요?"
    case openRequest
    /// "오픈 신청을 철회할까요?"
    case withdraw
    /// "MY 스팟을 삭제할까요?"
    case delete

    var id: Self { self }
}

/// 오픈 완료 팝업을 이미 봤는지 기억한다.
/// 서버에 "검수 결과 확인 여부" 플래그가 없어 로컬에 둔다.
/// - TODO(PV-40): 서버가 미확인 플래그를 내려주면 그쪽을 단일 진실 소스로 삼는다.
protocol OpenCompleteAcknowledging: Sendable {
    func hasAcknowledged(spotId: Int64) -> Bool
    func acknowledge(spotId: Int64)
}

struct UserDefaultsOpenCompleteStore: OpenCompleteAcknowledging {
    // UserDefaults 는 스레드 안전하지만 Sendable 로 표시돼 있지 않다.
    private nonisolated(unsafe) let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    private func key(_ spotId: Int64) -> String { "spot.openComplete.acknowledged.\(spotId)" }

    func hasAcknowledged(spotId: Int64) -> Bool {
        defaults.bool(forKey: key(spotId))
    }

    func acknowledge(spotId: Int64) {
        defaults.set(true, forKey: key(spotId))
    }
}
