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
final class ArchiveCoverImagePickerViewModel: NSObject, ObservableObject, PHPhotoLibraryChangeObserver {
    @Published var assets: [PHAsset] = []
    @Published var selectedAsset: PHAsset?
    @Published var selectedImageData: Data?
    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @Published var selectedAlbum: CoverAlbum = .recent

    /// 일부 접근(limited)에서 허용 사진이 바뀔 때 그리드를 자동 갱신하기 위한 옵저버 등록 여부.
    private var isObservingLibrary = false

    deinit {
        // 등록 여부와 무관하게 안전하게 해제.
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    func requestAndLoad() async {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        authorizationStatus = status
        guard status == .authorized || status == .limited else { return }
        registerLibraryObserverIfNeeded()
        await loadAssets(for: selectedAlbum)
    }

    /// 일부 접근일 때 "앱에 허용할 사진 관리" 시스템 시트를 띄운다.
    /// 여기서의 다중선택은 *커버 선택*이 아니라 *앱에 보여줄 사진 허용* 관리다.
    func presentLimitedLibraryPicker() {
        guard let vc = Self.topViewController() else { return }
        PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: vc)
    }

    private func registerLibraryObserverIfNeeded() {
        guard !isObservingLibrary else { return }
        PHPhotoLibrary.shared().register(self)
        isObservingLibrary = true
    }

    nonisolated func photoLibraryDidChange(_ changeInstance: PHChange) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            await self.loadAssets(for: self.selectedAlbum)
        }
    }

    private static func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let scene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
        var top = scene?.windows.first(where: \.isKeyWindow)?.rootViewController
            ?? scene?.windows.first?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }

    func selectAlbum(_ album: CoverAlbum) {
        selectedAlbum = album
        Task { await loadAssets(for: album) }
    }

    func select(_ asset: PHAsset) {
        selectedAsset = asset
        Task { selectedImageData = await loadFullData(for: asset) }
    }

    func selectCaptured(_ data: Data) {
        selectedAsset = nil
        selectedImageData = data
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
    let archiveName: String
    let currentImageData: Data?
    let onSelect: (Data) -> Void
    let onClose: () -> Void

    @StateObject private var vm = ArchiveCoverImagePickerViewModel()
    @State private var showCamera = false

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
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { data in vm.selectCaptured(data) }
                .ignoresSafeArea()
        }
    }

    // MARK: Nav bar

    private var navBar: some View {
        HStack {
            Button {
                onClose()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(UIAsset.Colors.gray0.swiftUIColor)
                    .padding(.vertical, 12)
                    .padding(.trailing, 8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()
            Text("사진첩")
                .pretendard(.heading(.medium))
                .foregroundStyle(.gray0)
            Spacer()

            Button("등록") {
                guard let data = vm.selectedImageData else { return }
                onSelect(data)
                onClose()
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
        .frame(height: 280)
        .clipped()
        .allowsHitTesting(false)
    }

    // MARK: Photo grid

    private var photoGrid: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                albumSelector
                if vm.authorizationStatus == .limited {
                    limitedAccessBanner
                }
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
                    .pretendard(.body(.large(.bold)))
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

    private var limitedAccessBanner: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("선택한 사진만 보여요")
                    .pretendard(.body(.medium(.bold)))
                    .foregroundStyle(.gray0)
                Text("커버로 쓸 사진이 없다면 더 추가해 주세요")
                    .pretendard(.body(.small()))
                    .foregroundStyle(.gray50)
            }
            Spacer(minLength: 0)
            Button {
                vm.presentLimitedLibraryPicker()
            } label: {
                Text("사진 추가")
                    .pretendard(.body(.medium(.bold)))
                    .foregroundStyle(.gray0)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(UIAsset.Colors.gray70.swiftUIColor)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(UIAsset.Colors.gray90.swiftUIColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private var cameraCell: some View {
        UIAsset.Colors.gray80.swiftUIColor
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                AssetImage(named: "ic_camera", renderingMode: .original, size: 24) {
                    Image(systemName: "camera")
                        .font(.system(size: 24, weight: .regular))
                        .foregroundStyle(UIAsset.Colors.gray50.swiftUIColor)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                // 카메라 사용 가능 환경(실기기)에서만 촬영 화면을 띄운다. (시뮬레이터 크래시 방지)
                guard UIImagePickerController.isSourceTypeAvailable(.camera) else { return }
                showCamera = true
            }
    }
}

// MARK: - Thumbnail cell

struct ArchivePhotoThumbnailView: View {
    let asset: PHAsset
    let isSelected: Bool

    @State private var thumbnail: UIImage?

    var body: some View {
        UIAsset.Colors.gray80.swiftUIColor
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if let img = thumbnail {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                }
            }
            .clipped()
            .overlay {
                if isSelected {
                    Rectangle()
                        .strokeBorder(UIAsset.Colors.sunsetOrange.swiftUIColor, lineWidth: 3)
                }
            }
            .contentShape(Rectangle())
            .task(id: asset.localIdentifier) { thumbnail = await loadThumbnail() }
    }

    private func loadThumbnail() async -> UIImage? {
        let opts = PHImageRequestOptions()
        // highQualityFormat: 결과 핸들러 1회 호출 보장(continuation 안전) + 필요 시 iCloud 다운로드.
        // fastFormat + 네트워크 차단이면 캐시 없는(일부 접근/ iCloud 최적화) 사진이 nil로 와 빈 칸이 됨.
        opts.deliveryMode = .highQualityFormat
        opts.resizeMode = .fast
        opts.isNetworkAccessAllowed = true
        return await withCheckedContinuation { continuation in
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: CGSize(width: 300, height: 300),
                contentMode: .aspectFill,
                options: opts
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }
}
