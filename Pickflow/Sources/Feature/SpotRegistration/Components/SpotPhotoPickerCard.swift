import PhotosUI
import SwiftUI
import UIKit

struct SpotPhotoPickerCard: View {
    @Binding var photoData: Data?

    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        let currentPhotoData = photoData
        let placeholderToken = PretendardStyle.body(.medium(.bold)).token

        ZStack(alignment: .topTrailing) {
            PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.spotPhotoCardBackground)
                    .frame(height: 200)
                    .overlay {
                        if let currentPhotoData, let image = UIImage(data: currentPhotoData) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            VStack(spacing: 8) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.system(size: 32, weight: .medium))
                                    .foregroundStyle(Color.spotPlaceholderText)

                                Text("등록할 스팟의 사진을\n선택해 주세요.")
                                    .font(placeholderToken.font)
                                    .tracking(placeholderToken.kerning)
                                    .lineSpacing(placeholderToken.lineSpacing)
                                    .foregroundStyle(Color.spotPlaceholderText)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(24)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("스팟 사진 선택")
            .onChange(of: selectedItem) { _, newValue in
                guard let newValue else { return }

                Task {
                    let data = try? await newValue.loadTransferable(type: Data.self)
                    await MainActor.run {
                        photoData = data
                    }
                }
            }

            if photoData != nil {
                Button {
                    selectedItem = nil
                    photoData = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.white, Color.black.opacity(0.35))
                }
                .padding(12)
                .accessibilityLabel("선택한 스팟 사진 제거")
            }
        }
    }
}
