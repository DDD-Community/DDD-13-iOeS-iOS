import SwiftUI

/// Dev Mode 에서 여는 보관함 목 화면.
///
/// 비공개로 전환된 저장 스팟은 서버에 만들려면 타 계정이 등록 → 오픈 신청 → 승인 → 비공개 전환까지
/// 거쳐야 해서 손으로 확인하기 어렵다. 목 데이터로 그 상태를 바로 띄운다.
struct ArchiveMockPreviewView: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel = ArchiveViewModel(
        archiveService: ArchiveMockService(),
        bookmarkService: ArchiveDebugBookmarkService(),
        authService: ArchiveDebugAuthService(state: ArchiveDebugSharedState(isSignedIn: true)),
        socialLoginService: ArchiveDebugSocialService(state: ArchiveDebugSharedState(isSignedIn: true)),
        locationService: ArchiveDebugLocationService()
    )

    var body: some View {
        ArchiveView(viewModel: viewModel)
            // 보관함 헤더가 상단 안전영역까지 덮어 기본 뒤로가기 버튼이 가려진다.
            // 목 화면을 빠져나갈 길이 없어지므로 닫기 버튼을 직접 얹는다.
            .overlay(alignment: .topLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(UIAsset.Colors.gray0.swiftUIColor)
                        .frame(width: 36, height: 36)
                        .background(Color.black.opacity(0.5), in: Circle())
                }
                .padding(.leading, 16)
                .padding(.top, 8)
                .accessibilityLabel("목 화면 닫기")
            }
            .navigationBarBackButtonHidden(true)
            .toolbar(.hidden, for: .navigationBar)
    }
}
