import SwiftUI

struct SpotBottomSheetActionButtons: View {
    let isMine: Bool
    let isBookmarked: Bool
    let onRoute: () -> Void
    let onBookmark: () -> Void

    var body: some View {
        if isMine {
            routeButton
        } else {
            HStack(spacing: 12) {
                routeButton
                bookmarkButton
            }
        }
    }

    private var routeButton: some View {
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
    }

    private var bookmarkButton: some View {
        Button(action: onBookmark) {
            HStack(spacing: 8) {
                Image(isBookmarked ? .icBookmarkFilled : .icBookmarkBorder)
                    .scaledToFit()
                    .foregroundStyle(.gray80)
                Text(isBookmarked ? "저장됨" : "저장하기")
                    .pretendard(.body(.large(.bold)))
                    .foregroundStyle(.gray80)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
        }
        .background(.gray0)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
