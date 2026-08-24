import SwiftUI

/// 공개된 내 스팟 하단의 "스팟 공개 ON/OFF" 섹션.
///
/// OFF 로 내리면 즉시 비공개(DRAFT)로 전환되지만, ON 으로 올리면 바로 공개가 아니라
/// 다시 검수를 거친다(오픈 신청). 두 방향이 비대칭이라는 점을 호출부가 알고 있어야 한다.
struct SpotVisibilityToggle: View {
    @Binding var isPublic: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text("스팟 공개")
                        .pretendard(.body(.large(.bold)))
                        .foregroundStyle(UIAsset.Colors.gray0.swiftUIColor)
                    Text(isPublic ? "ON" : "OFF")
                        .pretendard(.body(.large(.bold)))
                        .foregroundStyle(
                            isPublic
                                ? UIAsset.Colors.sunsetOrange.swiftUIColor
                                : UIAsset.Colors.gray50.swiftUIColor
                        )
                }
                Text(
                    isPublic
                        ? "다른 사용자에게 MY 스팟을 공개합니다."
                        : "다른 사용자에게 MY 스팟이 노출되지 않습니다."
                )
                .pretendard(.body(.small()))
                .foregroundStyle(UIAsset.Colors.gray30.swiftUIColor)
            }
            Spacer(minLength: 0)
            Toggle("", isOn: $isPublic)
                .labelsHidden()
                .tint(UIAsset.Colors.sunsetOrange.swiftUIColor)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(UIAsset.Colors.gray90.swiftUIColor, in: RoundedRectangle(cornerRadius: 8))
    }
}
