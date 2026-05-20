import SwiftUI

struct ArchiveHeaderView: View {
    let thumbnailURL: URL?
    var titleOpacity: CGFloat = 1
    var height: CGFloat = 240

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            backgroundImage
            gradient
            titleRow.opacity(titleOpacity)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipped()
    }

    private var backgroundImage: some View {
        ZStack {
            UIAsset.Colors.gray90.swiftUIColor
            if let url = thumbnailURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case let .success(image):
                        image.resizable().scaledToFill()
                    default:
                        UIAsset.Colors.gray90.swiftUIColor
                    }
                }
            } else {
                Image("onboarding_2_pic_0", bundle: PickflowResources.bundle)
                    .resizable()
                    .scaledToFill()
            }
        }
    }

    private var gradient: some View {
        LinearGradient(
            colors: [Color.black.opacity(0.5), Color.clear],
            startPoint: .bottom,
            endPoint: .center
        )
    }

    private var titleRow: some View {
        HStack(alignment: .center) {
            Text("나의 보관함")
                .pretendard(.heading(.large))
                .foregroundStyle(.white)
            Spacer()
            Button {
                // FIXME(KAN-53 범위 밖): 더보기 메뉴 미구현
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(12)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}

#Preview {
    ArchiveHeaderView(thumbnailURL: nil)
}
