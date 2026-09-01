import SwiftUI

struct SpotActionButtons: View {
    let isMine: Bool
    let isBookmarked: Bool
    let onRoute: () -> Void
    let onBookmark: () -> Void
    let onOpenSpot: () -> Void

    // MARK: - PV-40
    /// 내 스팟의 공개 상태. 이 값에 따라 우측 버튼이 오픈 신청 / 철회 / 추천으로 바뀐다.
    var publicationStatus: MySpotStatus?
    var canLike: Bool = false
    var isLiked: Bool = false
    var onWithdraw: () -> Void = {}
    var onLike: () -> Void = {}

    var body: some View {
        if isMine {
            mineLayout
        } else {
            defaultLayout
        }
    }

    private var defaultLayout: some View {
        HStack(spacing: 12) {
            Button(action: onRoute) {
                HStack(spacing: 6) {
                    AssetImage(named: "icNearMe", size: 24) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.white)
                    }
                    Text("길 안내 받기")
                        .pretendard(.body(.large(.bold)))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
            }
            .background(.sunsetOrange)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Button(action: onBookmark) {
                Image(isBookmarked ? "icBookmarkFilled" : "icBookmarkBorder", bundle: PickflowResources.bundle)
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .foregroundStyle(.gray95)
                    .frame(width: 24, height: 24)
                    .frame(width: 56, height: 56)
            }
            .background(.gray0)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // 추천은 공개된 스팟에만 붙는다. 큐레이션·타 유저 공개 스팟 모두 해당한다.
            if canLike {
                SpotLikeButton(isLiked: isLiked, action: onLike)
            }
        }
    }

    @ViewBuilder
    private var mineLayout: some View {
        // 추천 버튼이 붙는 상태(공개·반려)만 버튼 행 높이가 56 이다.
        switch publicationStatus {
        case .published, .rejected:
            HStack(spacing: 12) {
                routeButton(height: 56)
                SpotLikeButton(isLiked: isLiked, isEnabled: canLike, action: onLike)
            }
        case .pending, .reReviewPending:
            HStack(spacing: 12) {
                routeButton(height: 52)
                secondaryButton(title: "스팟 오픈 철회", action: onWithdraw)
            }
        case .draft, .unknown, .none:
            HStack(spacing: 12) {
                routeButton(height: 52)
                secondaryButton(title: "내 스팟 오픈하기", action: onOpenSpot)
            }
        }
    }

    private func routeButton(height: CGFloat) -> some View {
        Button(action: onRoute) {
            HStack(spacing: 6) {
                AssetImage(named: "icNearMe", size: 24) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                }
                Text("길 안내 받기")
                    .pretendard(.body(.large(.bold)))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
        }
        .background(.sunsetOrange)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func secondaryButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .pretendard(.body(.large(.bold)))
                .foregroundStyle(.gray80)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
        }
        .background(.gray0)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.gray80, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
