import SwiftUI

struct ArchiveHeaderView: View {
    let thumbnailURL: URL?
    var coverImageData: Data?
    var height: CGFloat = 240

    var body: some View {
        ZStack {
            backgroundImage
            gradient
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipped()
        .allowsHitTesting(false)
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
}

#Preview {
    ArchiveHeaderView(thumbnailURL: nil)
}
