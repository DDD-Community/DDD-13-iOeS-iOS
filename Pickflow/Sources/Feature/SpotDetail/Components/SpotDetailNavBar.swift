import SwiftUI

struct SpotDetailNavBar: View {
    let isBookmarked: Bool
    let onBookmark: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack {
            Spacer()
            HStack(spacing: 4) {
                Button(action: onBookmark) {
                    Image(isBookmarked ? "icBookmarkFilled" : "icBookmarkBorder", bundle: PickflowResources.bundle)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 32)
                        .frame(width: 48, height: 48)
                }

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 28, weight: .regular))
                        .foregroundStyle(.gray0)
                        .frame(width: 48, height: 48)
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .background(.gray95)
    }
}
