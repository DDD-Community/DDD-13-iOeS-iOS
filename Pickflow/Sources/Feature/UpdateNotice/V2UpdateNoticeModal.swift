import SwiftUI

/// V2 업데이트 후 서비스 최초 진입 시 한 번 노출되는 안내 모달.
struct V2UpdateNoticeModal: View {
    let onConfirm: () -> Void

    private let highlights = [
        "1. 햇살 · 야경 필터가 추가되었어요",
        "2. 이제 내 스팟을 공개할 수 있어요",
    ]

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 20) {
                newBadge

                VStack(spacing: 12) {
                    Text("V2 업데이트 안내")
                        .pretendard(.heading(.medium))
                        .foregroundStyle(UIAsset.Colors.gray0.swiftUIColor)

                    VStack(spacing: 4) {
                        ForEach(highlights, id: \.self) { line in
                            Text(line)
                                .pretendard(.body(.medium()))
                                .foregroundStyle(UIAsset.Colors.gray30.swiftUIColor)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }

            Button(action: onConfirm) {
                Text("확인했어요")
                    .pretendard(.body(.large(.bold)))
                    .foregroundStyle(UIAsset.Colors.gray0.swiftUIColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
            }
            .background(UIAsset.Colors.sunsetOrange.swiftUIColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(.top, 20)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .frame(width: 328)
        .background(UIAsset.Colors.gray90.swiftUIColor, in: RoundedRectangle(cornerRadius: 16))
    }

    private var newBadge: some View {
        Text("NEW")
            .pretendard(.body(.small(.bold)))
            .foregroundStyle(UIAsset.Colors.sunsetOrange.swiftUIColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background {
                RoundedRectangle(cornerRadius: 4)
                    .fill(UIAsset.Colors.sunsetOrange.swiftUIColor.opacity(0.15))
            }
    }
}
