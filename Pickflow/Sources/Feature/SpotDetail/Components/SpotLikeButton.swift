import SwiftUI

/// 추천(좋아요) 아이콘 버튼. 공개된 스팟에만 노출된다.
struct SpotLikeButton: View {
    let isLiked: Bool
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            // 북마크 버튼과 같은 짝(테두리/채움) 구성이다.
            Image(isLiked ? "icThumbUpFilled" : "icThumbUpBorder", bundle: PickflowResources.bundle)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundStyle(UIAsset.Colors.gray95.swiftUIColor)
                .frame(width: 56, height: 56)
        }
        .disabled(!isEnabled)
        .background(UIAsset.Colors.gray0.swiftUIColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityLabel(isLiked ? "추천 취소" : "추천")
    }
}
