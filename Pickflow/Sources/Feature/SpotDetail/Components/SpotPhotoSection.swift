import SwiftUI

struct SpotPhotoSection: View {
    let imageURL: String?

    var body: some View {
        AsyncImage(url: imageURL.flatMap(URL.init(string:))) { phase in
            switch phase {
            case let .success(image):
                image
                    .resizable()
                    .scaledToFill()
            default:
                ZStack {
                    Rectangle().fill(.gray90)
                    Image(systemName: "photo")
                        .font(.system(size: 28))
                        .foregroundStyle(.gray50)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
