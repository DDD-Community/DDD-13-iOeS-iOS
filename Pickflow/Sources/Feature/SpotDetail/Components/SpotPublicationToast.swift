import SwiftUI

/// 오픈 신청 접수 등 짧은 피드백 토스트. 사진 영역 위 중앙에 뜬다.
struct SpotPublicationToast: View {
    let message: String

    var body: some View {
        Text(message)
            .pretendard(.body(.large(.bold)))
            .foregroundStyle(UIAsset.Colors.gray90.swiftUIColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(UIAsset.Colors.gray0.swiftUIColor, in: RoundedRectangle(cornerRadius: 8))
    }
}
