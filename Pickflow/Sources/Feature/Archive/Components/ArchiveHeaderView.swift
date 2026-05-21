import SwiftUI

struct ArchiveHeaderView: View {
    let thumbnailURL: URL?
    var coverImageData: Data?
    var height: CGFloat = 240
    var onRenameArchiveTap: () -> Void = {}
    var onChangeCoverTap: () -> Void = {}

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            backgroundImage.allowsHitTesting(false)
            gradient.allowsHitTesting(false)
            menuButton
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipped()
    }

    private var backgroundImage: some View {
        ZStack {
            UIAsset.Colors.gray90.swiftUIColor
            if let data = coverImageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage).resizable().scaledToFill()
            } else if let url = thumbnailURL {
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
            colors: [Color.black.opacity(0.65), Color.clear],
            startPoint: .bottom,
            endPoint: .init(x: 0.5, y: 0.35)
        )
    }

    private var menuButton: some View {
        Menu {
            Button("보관함 이름 변경", action: onRenameArchiveTap)
            Button("커버 이미지 변경", action: onChangeCoverTap)
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.white)
                .padding(12)
        }
        .buttonStyle(.plain)
        .padding(.trailing, 4)
        .padding(.bottom, 12)
    }
}

#Preview {
    ArchiveHeaderView(thumbnailURL: nil)
}
