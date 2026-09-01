#if DEBUG
import SwiftUI

/// Dev Mode 에서 열 수 있는 목 화면 목록.
/// 새 화면을 확인할 일이 생기면 `entries` 에 한 줄 더한다.
@MainActor
struct MockScreenEntry: Identifiable {
    let id: String
    let title: String
    let description: String
    let destination: () -> AnyView

    init(id: String, title: String, description: String, @ViewBuilder destination: @escaping () -> some View) {
        self.id = id
        self.title = title
        self.description = description
        self.destination = { AnyView(destination()) }
    }
}

@MainActor
enum MockScreenCatalog {
    static var entries: [MockScreenEntry] {
        [
            MockScreenEntry(
                id: "detail-draft",
                title: "스팟 상세 — 나만보기",
                description: "MY 스팟 뱃지, [내 스팟 오픈하기]. 누르면 오픈 신청 바텀시트."
            ) { MockSpotDetailScreen(status: .draft) },

            MockScreenEntry(
                id: "detail-pending",
                title: "스팟 상세 — 검수중",
                description: "검수 중 뱃지, [스팟 오픈 철회]. 누르면 철회 바텀시트."
            ) { MockSpotDetailScreen(status: .pending) },

            MockScreenEntry(
                id: "detail-rejected",
                title: "스팟 상세 — 반려",
                description: "최상단 반려 사유 배너. [수정 후 재신청] 로 프리필된 등록 폼까지 이어진다."
            ) { MockSpotDetailScreen(status: .rejected) },

            MockScreenEntry(
                id: "detail-published",
                title: "스팟 상세 — 공개",
                description: "첫 진입 오픈 완료 팝업, 추천 버튼, 하단 스팟 공개 토글."
            ) { MockSpotDetailScreen(status: .published) },

            MockScreenEntry(
                id: "detail-other-user",
                title: "스팟 상세 — 타 유저 등록",
                description: "유저 등록 뱃지, 추천 수, 길 안내 + 북마크 + 추천 세 버튼."
            ) { MockSpotDetailScreen(status: .published, isMySpot: false) },

            MockScreenEntry(
                id: "detail-curated",
                title: "스팟 상세 — 큐레이션",
                description: "뱃지 없이 추천만. 출처 표기 줄은 시안·API 대기 중이라 아직 없다."
            ) { MockSpotDetailScreen(status: .published, isMySpot: false, isCurated: true) },

            MockScreenEntry(
                id: "preview-user-spot",
                title: "지도 미리보기 — 타 유저 등록 스팟",
                description: "타이틀 옆 유저 등록 뱃지와 추천 수."
            ) { MockUserSpotPreviewSheet() },

            MockScreenEntry(
                id: "archive-private",
                title: "보관함 — 비공개 전환된 저장 스팟",
                description: "두 번째 카드가 비공개, 세 번째가 삭제됨. 탭하면 삭제 확인창이 뜬다."
            ) { ArchiveMockPreviewView() },

            MockScreenEntry(
                id: "review-snackbar",
                title: "검수 결과 스낵바",
                description: "승인·반려 두 종류. 자동으로 사라지지 않는다."
            ) { MockReviewSnackbarScreen() },
        ]
    }
}
#endif
