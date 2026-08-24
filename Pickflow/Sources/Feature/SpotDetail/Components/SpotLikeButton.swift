import SwiftUI

/// 추천(좋아요) 아이콘 버튼. 공개된 스팟에서만 노출된다.
struct SpotLikeButton: View {
    let isLiked: Bool
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            AssetImage(named: "icThumbUp", renderingMode: .template, size: 24) {
                Image(systemName: isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                    .font(.system(size: 20))
            }
            .foregroundStyle(isLiked ? UIAsset.Colors.gray0.swiftUIColor : UIAsset.Colors.gray80.swiftUIColor)
            .frame(width: 56, height: 56)
        }
        .disabled(!isEnabled)
        .background(isLiked ? UIAsset.Colors.sunsetOrange.swiftUIColor : UIAsset.Colors.gray0.swiftUIColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityLabel(isLiked ? "추천 취소" : "추천")
    }
}
