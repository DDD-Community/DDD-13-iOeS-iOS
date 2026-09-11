import SwiftUI

/// 오픈 신청 / 철회 / 삭제 확인 바텀시트의 본문.
struct SpotPublicationSheetContent: View {
    let sheet: SpotPublicationSheet
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            grabber
            VStack(spacing: 12) {
                title
                    .pretendard(.heading(.medium))
                    .foregroundStyle(UIAsset.Colors.gray0.swiftUIColor)
                    .multilineTextAlignment(.center)
                Text(copy.body)
                    .pretendard(.body(.medium()))
                    .foregroundStyle(UIAsset.Colors.gray30.swiftUIColor)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            buttons
        }
        .padding(.horizontal, 20)
        // 시안의 하단 60 은 버튼에서 화면 맨 아래까지의 거리다(홈 인디케이터 영역 포함).
        .padding(.bottom, 60)
        .frame(maxWidth: .infinity)
        .background(
            UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: 20)
                .fill(UIAsset.Colors.gray95.swiftUIColor)
                .shadow(color: .black.opacity(0.15), radius: 16, y: -8)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private var grabber: some View {
        Capsule()
            .fill(Color(red: 217 / 255, green: 217 / 255, blue: 217 / 255))
            .frame(width: 45, height: 3)
            .padding(.vertical, 8)
    }

    /// 시안에서 동사만 주황으로 강조된다("MY 스팟을 **삭제**할까요?").
    private var title: Text {
        let highlighted = Text(copy.highlight)
            .foregroundColor(UIAsset.Colors.sunsetOrange.swiftUIColor)
        return (Text(copy.titlePrefix) + highlighted + Text(copy.titleSuffix))
    }

    private var buttons: some View {
        HStack(spacing: 12) {
            Button(action: onCancel) {
                Text("취소")
                    .pretendard(.body(.large(.bold)))
                    .foregroundStyle(UIAsset.Colors.gray80.swiftUIColor)
                    .frame(maxWidth: copy.isCancelHugging ? nil : .infinity)
                    .padding(.horizontal, copy.isCancelHugging ? 40 : 0)
                    .frame(height: 52)
            }
            .background(UIAsset.Colors.gray0.swiftUIColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Button(action: onConfirm) {
                Text(copy.confirmTitle)
                    .pretendard(.body(.large(.bold)))
                    .foregroundStyle(UIAsset.Colors.gray0.swiftUIColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
            }
            .background(UIAsset.Colors.sunsetOrange.swiftUIColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var copy: Copy { Copy(sheet: sheet) }

    struct Copy {
        let titlePrefix: String
        let highlight: String
        let titleSuffix: String
        let body: String
        let confirmTitle: String
        /// 오픈 신청 시트만 취소 버튼이 내용 폭(hug)이고 확정 버튼이 남는 폭을 채운다.
        let isCancelHugging: Bool

        init(sheet: SpotPublicationSheet) {
            switch sheet {
            case .openRequest:
                titlePrefix = "MY 스팟을 오픈할까요?"
                highlight = ""
                titleSuffix = ""
                body = "스팟을 오픈하면 다른 사용자들도 MY 스팟을\n볼 수 있어요. 오픈 신청하면 간단한 확인 절차 후\n지도에 표시돼요."
                confirmTitle = "오픈 신청하기"
                isCancelHugging = true
            case .withdraw:
                titlePrefix = "오픈 신청을 "
                highlight = "철회"
                titleSuffix = "할까요?"
                body = "오픈 신청이 철회된 MY 스팟은 나만 볼 수 있어요."
                confirmTitle = "오픈 철회하기"
                isCancelHugging = false
            case .delete:
                titlePrefix = "MY 스팟을 "
                highlight = "삭제"
                titleSuffix = "할까요?"
                body = "삭제한 스팟과 관련된 정보는 복구할 수 없어요."
                confirmTitle = "삭제하기"
                isCancelHugging = false
            }
        }
    }
}
