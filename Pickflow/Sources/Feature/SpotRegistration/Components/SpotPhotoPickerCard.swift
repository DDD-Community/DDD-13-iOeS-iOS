import PhotosUI
import SwiftUI
import UIKit

struct SpotPhotoPickerCard: View {
    @Binding var photoData: Data?
    /// 재신청처럼 이미 서버에 이미지가 있는 경우. 새로 고르기 전까지 이걸 보여준다.
    var existingImageUrl: String?

    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        let currentPhotoData = photoData

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
                        } else if let existingImageUrl, let url = URL(string: existingImageUrl) {
                            AsyncImage(url: url) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                SpotPhotoPlaceholder()
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            SpotPhotoPlaceholder()
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

private struct SpotPhotoPlaceholder: View {
    var body: some View {
        VStack(spacing: 8) {
            AssetImage(named: "icon_image_search", size: 32) {
                Image(systemName: "photo.badge.plus")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(Color.spotPlaceholderText)
            }

            Text("스팟의 분위기가\n잘 담긴 사진을 올려주세요.")
                .pretendard(.body(.medium(.bold)))
                .foregroundStyle(Color.spotPlaceholderText)
                .multilineTextAlignment(.center)
        }
        .padding(24)
    }
}
