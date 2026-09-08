#if DEBUG
import SwiftUI

/// Dev Mode 에서 여는 보관함 목 화면.
///
/// 비공개로 전환된 저장 스팟은 서버에 만들려면 타 계정이 등록 → 오픈 신청 → 승인 → 비공개 전환까지
/// 거쳐야 해서 손으로 확인하기 어렵다. 목 데이터로 그 상태를 바로 띄운다.
struct ArchiveMockPreviewView: View {
    @StateObject private var viewModel = ArchiveViewModel(
        archiveService: ArchiveMockService(),
        bookmarkService: ArchiveDebugBookmarkService(),
        authService: ArchiveDebugAuthService(state: ArchiveDebugSharedState(isSignedIn: true)),
        socialLoginService: ArchiveDebugSocialService(state: ArchiveDebugSharedState(isSignedIn: true)),
        locationService: ArchiveDebugLocationService()
    )

    var body: some View {
        MockScreenContainer {
            ArchiveView(viewModel: viewModel)
        }
    }
}
#endif
