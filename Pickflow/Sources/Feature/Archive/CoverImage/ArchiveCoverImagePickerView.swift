import Photos
import SwiftUI
import UIKit

// MARK: - Album type

enum CoverAlbum: String, CaseIterable {
    case recent = "최근 항목"
    case favorites = "즐겨찾기"
    case all = "모든 앨범"
}

// MARK: - ViewModel

@MainActor
final class ArchiveCoverImagePickerViewModel: ObservableObject {
    @Published var assets: [PHAsset] = []
    @Published var selectedAsset: PHAsset?
    @Published var selectedImageData: Data?
    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @Published var selectedAlbum: CoverAlbum = .recent

    func requestAndLoad() async {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        authorizationStatus = status
        guard status == .authorized || status == .limited else { return }
        await loadAssets(for: selectedAlbum)
    }

    func selectAlbum(_ album: CoverAlbum) {
        selectedAlbum = album
        Task { await loadAssets(for: album) }
    }

    func select(_ asset: PHAsset) {
        selectedAsset = asset
        Task { selectedImageData = await loadFullData(for: asset) }
    }

    private func loadAssets(for album: CoverAlbum) async {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.fetchLimit = 300

        switch album {
        case .recent:
            options.fetchLimit = 200
            let result = PHAsset.fetchAssets(with: .image, options: options)
            assets = collect(result)

        case .favorites:
            options.predicate = NSPredicate(format: "isFavorite == YES")
            let result = PHAsset.fetchAssets(with: .image, options: options)
            assets = collect(result)

        case .all:
            let result = PHAsset.fetchAssets(with: .image, options: options)
            assets = collect(result)
        }
    }

    private func collect(_ result: PHFetchResult<PHAsset>) -> [PHAsset] {
        var items: [PHAsset] = []
        result.enumerateObjects { asset, _, _ in items.append(asset) }
        return items
    }

    private nonisolated func loadFullData(for asset: PHAsset) async -> Data? {
        guard let resource = PHAssetResource.assetResources(for: asset)
            .first(where: { $0.type == .photo }) else { return nil }
        return await withCheckedContinuation { continuation in
            var accumulated = Data()
            let opts = PHAssetResourceRequestOptions()
            opts.isNetworkAccessAllowed = true
            PHAssetResourceManager.default().requestData(
                for: resource,
                options: opts,
                dataReceivedHandler: { accumulated.append($0) },
                completionHandler: { error in
                    continuation.resume(returning: error == nil ? accumulated : nil)
                }
            )
        }
    }
}

// MARK: - Picker View

struct ArchiveCoverImagePickerView: View {
    @Environment(\.dismiss) private var dismiss
    let archiveName: String
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
        ZStack(alignment: .bottomLeading) {
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

            LinearGradient(
                colors: [Color.black.opacity(0.65), Color.clear],
                startPoint: .bottom,
                endPoint: .init(x: 0.5, y: 0.35)
            )
            .frame(height: 280)
            .allowsHitTesting(false)

            Text(archiveName)
                .pretendard(.heading(.large))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 1)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .allowsHitTesting(false)
        }
    }

    // MARK: Photo grid

    private var photoGrid: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                albumSelector
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

    private var albumSelector: some View {
        Menu {
            ForEach(CoverAlbum.allCases, id: \.self) { album in
                Button {
                    vm.selectAlbum(album)
                } label: {
                    HStack {
                        Text(album.rawValue)
                        if vm.selectedAlbum == album {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(vm.selectedAlbum.rawValue)
                    .pretendard(.body(.medium(.bold)))
                    .foregroundStyle(.gray0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(UIAsset.Colors.gray0.swiftUIColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
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
