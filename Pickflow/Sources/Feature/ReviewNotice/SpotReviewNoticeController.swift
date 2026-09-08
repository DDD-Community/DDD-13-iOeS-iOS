import Foundation
import UIKit

/// 검수 결과 스낵바가 안내할 내용.
struct SpotReviewNotice: Equatable {
    enum Kind: Equatable {
        case approved
        case rejected
    }

    /// 확인(check-status) 처리에 쓴다. 화면엔 노출되지 않는다.
    let historyId: Int64
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

/// 오픈 신청 결과를 스낵바와 저장 탭 인디케이터로 안내한다.
///
/// 검수완료 알림 히스토리 API(`spot-open-review-histories`)를 단일 진실 소스로 쓴다.
/// 확인 여부(check_yn)는 서버가 기록하므로 로컬에 "본 것"을 따로 저장하지 않는다.
/// (이전엔 my-spots 상태를 로컬에 기록해 두고 비교하는 임시 방식을 썼다 — 전용 API가
/// 생겨 대체됐다. docs/PV-40/backlog.md 참고.)
///
/// "검수중인 스팟이 있는지"는 이 API 가 알려주지 않아 my-spots 조회로 별도 판단한다.
@MainActor
final class SpotReviewNoticeController: ObservableObject {
    @Published private(set) var notice: SpotReviewNotice?
    /// 검수중이거나 결과를 아직 확인하지 않았을 때 켜진다.
    @Published private(set) var showsSavedTabIndicator = false
    /// 스팟 바텀시트가 떠 있는 동안에는 스낵바를 잠시 감춘다(소멸이 아니다).
    @Published private(set) var isSpotSheetPresented = false

    /// 실제로 화면에 그릴지. 소멸(notice == nil)과 일시 숨김을 구분한다.
    var isNoticeVisible: Bool { notice != nil && !isSpotSheetPresented }

    private let archiveService: ArchiveServiceProtocol
    private let reviewHistoryService: SpotReviewHistoryServiceProtocol
    private let tokenStore: TokenStoreProtocol

    /// 아직 검수 중인 스팟이 있는지. 인디케이터 판단에 쓴다.
    private var hasSpotUnderReview = false
    /// 한 번에 여러 건이 완료된 경우 나머지는 여기 쌓아 뒀다가 확인할 때마다 하나씩 꺼낸다.
    private var queue: [SpotReviewNotice] = []
    nonisolated(unsafe) private var notificationObservers: [NSObjectProtocol] = []

    init(
        archiveService: ArchiveServiceProtocol,
        reviewHistoryService: SpotReviewHistoryServiceProtocol,
        tokenStore: TokenStoreProtocol
    ) {
        self.archiveService = archiveService
        self.reviewHistoryService = reviewHistoryService
        self.tokenStore = tokenStore
        setupNotificationObservers()
    }

    deinit {
        notificationObservers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    /// 호출 시점: 로그인 직후·보관함 목록 조회(.spotReviewCheckRequested)와
    /// 앱 포그라운드 복귀. 지도 탐색화면 최초 진입은 ContentView 가 reviewNotice 를
    /// 직접 들고 있어 거기서 바로 refresh() 를 부른다.
    private func setupNotificationObservers() {
        let names: [Notification.Name] = [
            .spotReviewCheckRequested,
            UIApplication.willEnterForegroundNotification,
        ]
        notificationObservers = names.map { name in
            NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.refresh()
                }
            }
        }
    }

    func refresh() async {
        guard (try? tokenStore.load()) != nil else { return }

        if let spots = try? await archiveService.fetchMySpots(page: 0, latitude: nil, longitude: nil).spots {
            hasSpotUnderReview = spots.contains { $0.status.isUnderReview }
        }

        if notice == nil, queue.isEmpty, let histories = try? await reviewHistoryService.fetchUncheckedHistories() {
            // 반려를 먼저 보여준다 — 승인은 놓쳐도 스팟 상세에서 다시 확인할 수 있지만,
            // 반려는 재신청 여부를 결정해야 해서 더 급하다.
            let rejected = histories.rejected.map {
                SpotReviewNotice(historyId: $0.historyId, spotId: $0.spotId, kind: .rejected)
            }
            let approved = histories.approved.map {
                SpotReviewNotice(historyId: $0.historyId, spotId: $0.spotId, kind: .approved)
            }
            queue = rejected + approved
            if !queue.isEmpty { notice = queue.removeFirst() }
        }

        updateIndicator()
    }

    func dismissNotice() {
        acknowledgeAndAdvance()
    }

    /// 이동 버튼. 열어야 할 스팟 id 를 돌려주고 스낵바를 닫는다.
    func openNoticeTarget() -> Int64? {
        let target = notice?.spotId
        acknowledgeAndAdvance()
        return target
    }

    func setSpotSheetPresented(_ isPresented: Bool) {
        isSpotSheetPresented = isPresented
    }

    private func acknowledgeAndAdvance() {
        guard let current = notice else { return }
        let historyId = current.historyId
        Task { try? await reviewHistoryService.markChecked(historyId: historyId) }
        notice = queue.isEmpty ? nil : queue.removeFirst()
        updateIndicator()
    }

    private func updateIndicator() {
        showsSavedTabIndicator = hasSpotUnderReview || notice != nil || !queue.isEmpty
    }
}
