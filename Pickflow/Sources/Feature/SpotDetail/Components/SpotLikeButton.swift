import SwiftUI

/// 추천(좋아요) 아이콘 버튼. 공개된 스팟에서만 노출된다.
struct SpotLikeButton: View {
    let isLiked: Bool
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            // TODO(PV-40): 디자인 시스템의 ic_thumb_up 에셋을 아직 못 받았다.
            //              (Figma 컴포넌트 노드에서 export 하면 플레이스홀더 글리프가 나온다.)
            //              실제 아이콘을 받으면 이 심볼을 교체할 것.
            Image(systemName: isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(isLiked ? UIAsset.Colors.gray0.swiftUIColor : UIAsset.Colors.gray80.swiftUIColor)
                .frame(width: 56, height: 56)
        }
        .disabled(!isEnabled)
        .background(isLiked ? UIAsset.Colors.sunsetOrange.swiftUIColor : UIAsset.Colors.gray0.swiftUIColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityLabel(isLiked ? "추천 취소" : "추천")
    }
}
