import Foundation

/// V2 업데이트 안내를 이미 확인했는지 기억한다.
protocol V2NoticeAcknowledging: Sendable {
    var hasAcknowledged: Bool { get }
    func acknowledge()
}

struct UserDefaultsV2NoticeStore: V2NoticeAcknowledging {
    private static let key = "notice.v2Update.acknowledged"

    // UserDefaults 는 스레드 안전하지만 Sendable 로 표시돼 있지 않다.
    private nonisolated(unsafe) let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var hasAcknowledged: Bool { defaults.bool(forKey: Self.key) }

    func acknowledge() { defaults.set(true, forKey: Self.key) }
}

/// V2 업데이트 안내 모달의 노출 여부를 판단한다.
///
/// 노출 조건은 두 가지다. 아직 확인하지 않았고, 노출 기간이 끝나지 않았을 것.
/// 확인하지 않은 채 앱을 껐다 켜면 기간 안에서는 다시 뜬다("확인" 이 유일한 종료 조건).
@MainActor
final class V2UpdateNoticeController: ObservableObject {
    @Published private(set) var isPresented = false

    private let store: V2NoticeAcknowledging
    private let endDate: Date
    private let clock: @Sendable () -> Date

    init(
        store: V2NoticeAcknowledging = UserDefaultsV2NoticeStore(),
        endDate: Date = V2UpdateNotice.endDate,
        clock: @escaping @Sendable () -> Date = Date.init
    ) {
        self.store = store
        self.endDate = endDate
        self.clock = clock
    }

    func checkOnLaunch() {
        isPresented = !store.hasAcknowledged && clock() < endDate
    }

    func acknowledge() {
        isPresented = false
        store.acknowledge()
    }
}

enum V2UpdateNotice {
    /// 노출 종료 시각.
    ///
    /// 기획은 "업데이트 후 약 2주" 라는 절대 기간을 말한다. 유저별 최초 실행 기준이 아니라
    /// 모두에게 같은 시점에 끝나야 하므로 고정 시각으로 둔다.
    ///
    /// - TODO(PV-40): 값이 앱에 박혀 있어 심사 지연이나 배포 일정 변경에 대응할 수 없다.
    ///   `/v1/app/config/ios` 응답(AppVersionPolicy)에 필드를 하나 추가해 서버에서
    ///   내려주는 편이 안전하다. supportEmail·termsPolicies 처럼 옵셔널로 붙이면 된다.
    /// - TODO(PV-40): 실제 V2 배포일이 정해지면 아래 날짜를 교체할 것. 현재 값은 임시다.
    static let endDate: Date = {
        var components = DateComponents()
        components.year = 2026
        components.month = 9
        components.day = 15
        components.timeZone = TimeZone(identifier: "Asia/Seoul")
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        return calendar.date(from: components) ?? Date.distantPast
    }()
}
