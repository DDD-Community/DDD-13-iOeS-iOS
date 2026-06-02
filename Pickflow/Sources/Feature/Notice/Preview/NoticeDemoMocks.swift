#if DEBUG
import Foundation

/// 공지사항 테스트(데모) 모드 플래그.
/// 켜는 법:
///  - Xcode: Product > Scheme > Edit Scheme… > Run > Arguments >
///    "Arguments Passed On Launch"에 `-NOTICE_DEMO 1` 추가 후 실행
///  - CLI: `xcrun simctl launch <device> com.pickflow -NOTICE_DEMO 1`
/// 켜지면 로그인/네트워크 없이 앱이 곧바로 공지사항 리스트(mock)로 진입한다.
enum NoticeDemoFlag {
    static var isOn: Bool {
        if ProcessInfo.processInfo.environment["NOTICE_DEMO"] == "1" { return true }
        return UserDefaults.standard.bool(forKey: "NOTICE_DEMO")
    }
}

/// 테스트 모드용 mock 공지 서비스. 실 네트워크 없이 샘플 목록/상세를 반환한다.
final class DemoNoticeService: NoticeServiceProtocol, Sendable {
    private static let items: [NoticeListItem] = [
        NoticeListItem(
            postId: 1,
            title: "[공지] 픽플로우 개인정보처리방침 개정 안내드립니다. 픽플로우 개인정보처리방침 개정 안내드립니다.",
            createdAt: "2026-05-09",
            pinned: true,
            content: "개인정보처리방침이 2026년 5월 9일자로 개정됩니다. 변경 사항을 확인해 주세요."
        ),
        NoticeListItem(postId: 2, title: "[공지] 픽플로우 개인정보처리방침 개정 안내드립니다.", createdAt: "2026-05-08", pinned: true, content: "수집 항목 및 보유 기간 일부가 변경되었습니다. 자세한 내용은 본문을 확인해 주세요."),
        NoticeListItem(postId: 3, title: "6/16 시스템 정기 점검 안내", createdAt: "2026-05-02", pinned: false, content: "6월 16일 02:00 ~ 04:00 동안 서비스 이용이 일시 중단됩니다."),
        NoticeListItem(postId: 4, title: "신규 기능 '노을 알림' 출시 안내", createdAt: "2026-04-28", pinned: false, content: "원하는 스팟의 일몰 시간에 맞춰 알림을 받아보세요."),
        NoticeListItem(postId: 5, title: "이용약관 개정 안내 (2026.04)", createdAt: "2026-04-15", pinned: false, content: "이용약관 제12조, 제15조가 개정되었습니다."),
    ]

    func fetchNotices(masterId _: Int64, page: Int) async throws -> NoticePage {
        try await Task.sleep(nanoseconds: 250_000_000)
        return NoticePage(items: page == 0 ? Self.items : [], page: page, hasNext: false)
    }

    func fetchNoticeDetail(postId: Int64, masterId: Int64) async throws -> NoticeDetail {
        try await Task.sleep(nanoseconds: 250_000_000)
        let item = Self.items.first { $0.postId == postId }
        return NoticeDetail(
            masterId: masterId,
            postId: postId,
            title: item?.title ?? "공지사항",
            createdAt: item?.createdAt ?? "2026-05-09",
            content: """
            안녕하세요, 픽플로우입니다.

            본 공지는 테스트 모드 mock 데이터로 표시되고 있습니다. 실제 본문은 서버 응답의 content 필드를 그대로 렌더링하며, 줄바꿈은 유지됩니다.

            - 항목 1
            - 항목 2
            - 항목 3

            감사합니다.
            """
        )
    }
}
#endif
