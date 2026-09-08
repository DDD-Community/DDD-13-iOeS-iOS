import SwiftUI

/// 스팟 타이틀 옆에 붙는 상태 뱃지.
struct SpotStatusBadge: View {
    enum Style: Equatable {
        /// 내가 등록한 스팟 (나만보기·공개)
        case mySpot
        /// 검수중 / 재검토 대기
        case underReview
        /// 오픈 반려
        case rejected
        /// 다른 유저가 등록해 공개한 스팟
        case userRegistered

        var text: String {
            switch self {
            case .mySpot: "MY 스팟"
            case .underReview: "검수 중"
            case .rejected: "오픈 반려"
            case .userRegistered: "유저 등록"
            }
        }

        var foreground: Color {
            switch self {
            case .mySpot: UIAsset.Colors.sunsetOrange.swiftUIColor
            case .underReview, .rejected: UIAsset.Colors.gray20.swiftUIColor
            // MY 스팟(주황)과 구분되도록 앰버를 쓴다.
            case .userRegistered: Color.spotUserRegistered
            }
        }

        /// 검수중만 채움(Surface), 나머지는 테두리(Line).
        var fill: Color? {
            switch self {
            case .underReview: UIAsset.Colors.gray20.swiftUIColor.opacity(0.15)
            case .mySpot, .rejected, .userRegistered: nil
            }
        }

        var border: Color? {
            switch self {
            case .mySpot: UIAsset.Colors.sunsetOrange.swiftUIColor
            case .rejected: UIAsset.Colors.gray20.swiftUIColor
            case .userRegistered: Color.spotUserRegistered
            case .underReview: nil
            }
        }
    }

    let style: Style

    /// 유저 등록 스팟의 공개 상태를 뱃지 스타일로 옮긴다. 큐레이션 스팟이면 뱃지가 없다.
    init?(status: MySpotStatus?, isMySpot: Bool) {
        guard isMySpot else { return nil }
        switch status {
        case .pending, .reReviewPending: style = .underReview
        case .rejected: style = .rejected
        case .draft, .published, .unknown, .none: style = .mySpot
        }
    }

    init(style: Style) {
        self.style = style
    }

    var body: some View {
        Text(style.text)
            .pretendard(.body(.small(.bold)))
            .foregroundStyle(style.foreground)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background {
                RoundedRectangle(cornerRadius: 4)
                    .fill(style.fill ?? .clear)
            }
            .overlay {
                if let border = style.border {
                    RoundedRectangle(cornerRadius: 4).stroke(border, lineWidth: 1)
                }
            }
            .fixedSize()
    }
}
