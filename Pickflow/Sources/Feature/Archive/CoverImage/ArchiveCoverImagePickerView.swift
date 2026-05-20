import Photos
import SwiftUI
import UIKit

// MARK: - ViewModel

@MainActor
final class ArchiveCoverImagePickerViewModel: ObservableObject {
    @Published var assets: [PHAsset] = []
    @Published var selectedAsset: PHAsset?
    @Published var selectedImageData: Data?
    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined

    func requestAndLoad() async {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        authorizationStatus = status
        guard status == .authorized || status == .limited else { return }
        await loadRecentAssets()
    }

    func select(_ asset: PHAsset) {
        selectedAsset = asset
        Task { selectedImageData = await loadFullData(for: asset) }
    }

    private func loadRecentAssets() async {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.fetchLimit = 200
        let result = PHAsset.fetchAssets(with: .image, options: options)
        var fetched: [PHAsset] = []
        result.enumerateObjects { asset, _, _ in fetched.append(asset) }
        assets = fetched
    }

    private func loadFullData(for asset: PHAsset) async -> Data? {
        await withCheckedContinuation { continuation in
            let opts = PHImageRequestOptions()
            opts.deliveryMode = .highQualityFormat
            opts.isNetworkAccessAllowed = true
            opts.isSynchronous = false
            var resumed = false
            PHImageManager.default().requestImageDataAndOrientation(
                for: asset, options: opts
            ) { data, _, _, info in
                guard !resumed,
                      (info?[PHImageResultIsDegradedKey] as? Bool) != true else { return }
                resumed = true
                continuation.resume(returning: data)
            }
        }
    }
}

// MARK: - Picker View

struct ArchiveCoverImagePickerView: View {
    @Environment(\.dismiss) private var dismiss
    let currentImageData: Data?
    let onSelect: (Data) -> Void

    @StateObject private var vm = ArchiveCoverImagePickerViewModel()

    private var previewImage: UIImage? {
        if let data = vm.selectedImageData ?? currentImageData { return UIImage(data: data) }
        return nil
    }

    var body: some View {
        VStack(spacing: 0) {
            navBar
            previewSection
            photoGrid
        }
        .background(UIAsset.Colors.gray95.swiftUIColor.ignoresSafeArea())
        .task { await vm.requestAndLoad() }
    }

    // MARK: Nav bar

    private var navBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(UIAsset.Colors.gray0.swiftUIColor)
                    .padding(.vertical, 12)
                    .padding(.trailing, 8)
            }
            .buttonStyle(.plain)

            Spacer()
            Text("사진첩")
                .pretendard(.body(.large(.bold)))
                .foregroundStyle(.gray0)
            Spacer()

            Button("등록") {
                guard let data = vm.selectedImageData else { return }
                onSelect(data)
                dismiss()
            }
            .pretendard(.body(.medium(.bold)))
            .foregroundStyle(vm.selectedImageData != nil
                ? UIAsset.Colors.sunsetOrange.swiftUIColor
                : UIAsset.Colors.gray60.swiftUIColor)
            .disabled(vm.selectedImageData == nil)
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
        .background(UIAsset.Colors.gray95.swiftUIColor)
    }

    // MARK: Preview

    private var previewSection: some View {
        Group {
            if let img = previewImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else {
                Image("onboarding_2_pic_0", bundle: PickflowResources.bundle)
                    .resizable()
                    .scaledToFill()
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 280)
        .clipped()
        .overlay(alignment: .bottomLeading) {
            LinearGradient(
                colors: [Color.black.opacity(0.5), Color.clear],
                startPoint: .bottom, endPoint: .center
            )
            .allowsHitTesting(false)
        }
    }

    // MARK: Photo grid

    private var photoGrid: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 4) {
                    Text("최근 항목")
                        .pretendard(.body(.medium(.bold)))
                        .foregroundStyle(.gray0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(UIAsset.Colors.gray0.swiftUIColor)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 4),
                    spacing: 2
                ) {
                    cameraCell
                    ForEach(vm.assets, id: \.localIdentifier) { asset in
                        ArchivePhotoThumbnailView(
                            asset: asset,
                            isSelected: vm.selectedAsset?.localIdentifier == asset.localIdentifier
                        )
                        .onTapGesture { vm.select(asset) }
                    }
                }
            }
        }
    }

    private var cameraCell: some View {
        UIAsset.Colors.gray80.swiftUIColor
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                Image(systemName: "camera")
                    .font(.system(size: 24, weight: .regular))
                    .foregroundStyle(UIAsset.Colors.gray50.swiftUIColor)
            }
    }
}

// MARK: - Thumbnail cell

struct ArchivePhotoThumbnailView: View {
    let asset: PHAsset
    let isSelected: Bool

    @State private var thumbnail: UIImage?

    var body: some View {
        ZStack {
            UIAsset.Colors.gray80.swiftUIColor
            if let img = thumbnail {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            }
            if isSelected {
                Rectangle()
                    .strokeBorder(UIAsset.Colors.sunsetOrange.swiftUIColor, lineWidth: 3)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipped()
        .task(id: asset.localIdentifier) { thumbnail = await loadThumbnail() }
    }

    private func loadThumbnail() async -> UIImage? {
        let opts = PHImageRequestOptions()
        opts.deliveryMode = .fastFormat
        opts.resizeMode = .fast
        opts.isNetworkAccessAllowed = false
        return await withCheckedContinuation { continuation in
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: CGSize(width: 200, height: 200),
                contentMode: .aspectFill,
                options: opts
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }
}
