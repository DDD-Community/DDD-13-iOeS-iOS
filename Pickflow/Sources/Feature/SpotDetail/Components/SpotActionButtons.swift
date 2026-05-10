import SwiftUI

struct SpotActionButtons: View {
    let isMine: Bool
    let isBookmarked: Bool
    let onRoute: () -> Void
    let onBookmark: () -> Void
    let onOpenSpot: () -> Void

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
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .frame(width: 56, height: 56)
            }
            .background(.gray0)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var mineLayout: some View {
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
                .frame(height: 52)
            }
            .background(.sunsetOrange)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Button(action: onOpenSpot) {
                Text("내 스팟 오픈하기")
                    .pretendard(.body(.large(.bold)))
                    .foregroundStyle(.gray0)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
            }
            .background(.gray95)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.gray80, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}
