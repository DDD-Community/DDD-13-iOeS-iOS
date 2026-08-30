import Foundation

/// 검수 결과 스낵바가 안내할 내용.
struct SpotReviewNotice: Equatable {
    enum Kind: Equatable {
        case approved
        case rejected
    }

    let spotId: Int64
    let kind: Kind

    var title: String {
        switch kind {
        case .approved: "MY 스팟이 오픈됐어요!"
        case .rejected: "MY 스팟 오픈이 반려되었어요"
        }
    }

    var message: String {
        switch kind {
        case .approved: "신청한 스팟이 등록되었어요."
        case .rejected: "반려 사유를 확인해 주세요."
        }
    }

    var actionTitle: String {
        switch kind {
        case .approved: "바로 가기"
        case .rejected: "확인하기"
        }
    }
}

/// 내 스팟의 공개 상태를 마지막으로 확인한 시점 기준으로 기억한다.
protocol SpotReviewSeenStoring: Sendable {
    func lastSeenStatuses() -> [Int64: MySpotStatus]
    func save(_ statuses: [Int64: MySpotStatus])
}

struct UserDefaultsSpotReviewSeenStore: SpotReviewSeenStoring {
    private static let key = "spot.review.lastSeenStatuses"

    // UserDefaults 는 스레드 안전하지만 Sendable 로 표시돼 있지 않다.
    private nonisolated(unsafe) let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func lastSeenStatuses() -> [Int64: MySpotStatus] {
        guard let raw = defaults.dictionary(forKey: Self.key) as? [String: String] else { return [:] }
        return raw.reduce(into: [:]) { result, pair in
            guard let id = Int64(pair.key), let status = MySpotStatus(rawValue: pair.value) else { return }
            result[id] = status
        }
    }

    func save(_ statuses: [Int64: MySpotStatus]) {
        let raw = statuses.reduce(into: [String: String]()) { result, pair in
            result[String(pair.key)] = pair.value.rawValue
        }
        defaults.set(raw, forKey: Self.key)
    }
}

/// 오픈 신청 결과를 스낵바와 저장 탭 인디케이터로 알린다.
///
/// 서버에 "검수 결과를 확인했는지" 를 나타내는 플래그가 없어서, 내 스팟 목록의 상태를
/// 로컬에 기록해 두고 다음에 읽은 값과 비교해 결과 도착을 감지한다.
/// - TODO(PV-40): 서버가 미확인 플래그를 내려주면 그쪽을 단일 진실 소스로 삼을 것.
///   지금 방식은 앱을 지웠다 깔거나 기기를 바꾸면 결과 안내를 놓친다.
@MainActor
final class SpotReviewNoticeController: ObservableObject {
    @Published private(set) var notice: SpotReviewNotice?
    /// 오픈 신청 중이거나 결과를 아직 확인하지 않았을 때 켜진다.
    @Published private(set) var showsSavedTabIndicator = false
    /// 스팟 바텀시트가 떠 있는 동안에는 스낵바를 잠시 감춘다(소멸이 아니다).
    @Published private(set) var isSpotSheetPresented = false

    /// 실제로 화면에 그릴지. 소멸(notice == nil)과 일시 숨김을 구분한다.
    var isNoticeVisible: Bool { notice != nil && !isSpotSheetPresented }

    private let archiveService: ArchiveServiceProtocol
    private let tokenStore: TokenStoreProtocol
    private let store: SpotReviewSeenStoring

    /// 아직 검수 중인 스팟이 있는지. 인디케이터 판단에 쓴다.
    private var hasSpotUnderReview = false

    init(
        archiveService: ArchiveServiceProtocol,
        tokenStore: TokenStoreProtocol,
        store: SpotReviewSeenStoring = UserDefaultsSpotReviewSeenStore()
    ) {
        self.archiveService = archiveService
        self.tokenStore = tokenStore
        self.store = store
    }

    func refresh() async {
        guard (try? tokenStore.load()) != nil else { return }
        guard let spots = try? await archiveService.fetchMySpots(page: 0, latitude: nil, longitude: nil).spots else {
            return
        }

        let seen = store.lastSeenStatuses()
        let current = spots.reduce(into: [Int64: MySpotStatus]()) { $0[$1.spotId] = $1.status }
        hasSpotUnderReview = spots.contains { $0.status.isUnderReview }

        // 검수를 기다리던 스팟만 결과로 본다. 나만보기에서 바로 공개로 바뀐 것은
        // 유저가 직접 되돌린 경우라 안내할 결과가 아니다.
        if notice == nil {
            notice = spots.compactMap { spot -> SpotReviewNotice? in
                guard seen[spot.spotId]?.isUnderReview == true else { return nil }
                switch spot.status {
                case .published: return SpotReviewNotice(spotId: spot.spotId, kind: .approved)
                case .rejected: return SpotReviewNotice(spotId: spot.spotId, kind: .rejected)
                default: return nil
                }
            }.first
        }

        // 아직 안내하지 않은 결과는 "본 것" 으로 기록하지 않는다. 확인 전에 기록하면
        // 앱을 껐다 켰을 때 안내가 사라진다.
        var toStore = seen
        for spot in spots where notice?.spotId != spot.spotId {
            toStore[spot.spotId] = spot.status
        }
        store.save(toStore)

        updateIndicator()
    }

    func dismissNotice() {
        markNoticeSeen()
    }

    /// 이동 버튼. 열어야 할 스팟 id 를 돌려주고 스낵바를 닫는다.
    func openNoticeTarget() -> Int64? {
        let target = notice?.spotId
        markNoticeSeen()
        return target
    }

    func setSpotSheetPresented(_ isPresented: Bool) {
        isSpotSheetPresented = isPresented
    }

    private func markNoticeSeen() {
        guard let notice else { return }
        var statuses = store.lastSeenStatuses()
        statuses[notice.spotId] = notice.kind == .approved ? .published : .rejected
        store.save(statuses)
        self.notice = nil
        updateIndicator()
    }

    private func updateIndicator() {
        showsSavedTabIndicator = hasSpotUnderReview || notice != nil
    }
}
