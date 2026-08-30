import SwiftUI

struct SpotPhotoSection: View {
    let imageURL: String?
    let recordedTime: String?
    /// 서버가 주소를 채우지 못하면 null 로 온다. 그럴 땐 주소 줄을 통째로 감춘다.
    let address: String?

    @State private var isFullScreenPresented: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            photoView
                .contentShape(Rectangle())
                .onTapGesture {
                    if imageURL != nil {
                        isFullScreenPresented = true
                    }
                }
                .fullScreenCover(isPresented: $isFullScreenPresented) {
                    SpotPhotoFullScreenView(
                        imageURL: imageURL,
                        onClose: { isFullScreenPresented = false }
                    )
                }
            if let address, !address.isEmpty {
                HStack(spacing: 4) {
                    AssetImage(named: "icLocationOn", size: 16) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.gray50)
                    }
                    Text(address)
                        .pretendard(.label(.medium))
                        .foregroundStyle(.gray30)
                        .lineLimit(1)
                    Spacer()
                }
            }
        }
    }

    @ViewBuilder
    private var photoView: some View {
        AsyncImage(url: imageURL.flatMap(URL.init(string:))) { phase in
            switch phase {
            case let .success(image):
                image
                    .resizable()
                    .scaledToFill()
            default:
                Rectangle().fill(.gray90)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(alignment: .topLeading) {
            if imageURL != nil, let recordedTime, !recordedTime.isEmpty {
                Text(DateFormatter.pickflowDisplayTime(from: recordedTime))
                    .pretendard(.body(.small(.bold)))
                    .foregroundStyle(Color(red: 1, green: 161/255, blue: 0))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.black.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .padding(8)
            }
        }
    }
}
