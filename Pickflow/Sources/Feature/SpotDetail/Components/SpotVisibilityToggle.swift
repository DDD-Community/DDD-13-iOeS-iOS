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
                .toggleStyle(SpotSwitchToggleStyle())
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(UIAsset.Colors.gray90.swiftUIColor, in: RoundedRectangle(cornerRadius: 8))
    }
}

/// 시안 치수(트랙 51x31, 노브 27)에 맞춘 스위치.
/// 기본 `Toggle` 은 UIKit 백업 컨트롤이라 스냅샷에서 노브가 그려지지 않는다.
struct SpotSwitchToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            Capsule()
                .fill(
                    configuration.isOn
                        ? UIAsset.Colors.sunsetOrange.swiftUIColor
                        : UIAsset.Colors.gray70.swiftUIColor
                )
                .frame(width: 51, height: 31)
                .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                    Circle()
                        .fill(UIAsset.Colors.gray0.swiftUIColor)
                        .frame(width: 27, height: 27)
                        .padding(.horizontal, 2)
                }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
        .accessibilityAddTraits(configuration.isOn ? [.isButton, .isSelected] : .isButton)
    }
}
