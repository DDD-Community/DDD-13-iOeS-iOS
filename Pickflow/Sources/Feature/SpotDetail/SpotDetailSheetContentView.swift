import SwiftUI
import UIKit

struct SpotDetailSheetContentView: View {
    let preview: SpotPreviewResponse
    let isBookmarked: Bool
    let onClose: () -> Void
    let onRoute: () -> Void
    let onBookmark: () -> Void
    @State private var isAddressExpanded: Bool
    @State private var isPhotoFullScreenPresented: Bool = false
    @State private var copyToast: String?

    init(
        preview: SpotPreviewResponse,
        isBookmarked: Bool,
        initialAddressExpanded: Bool = false,
        onClose: @escaping () -> Void = {},
        onRoute: @escaping () -> Void = {},
        onBookmark: @escaping () -> Void = {}
    ) {
        self.preview = preview
        self.isBookmarked = isBookmarked
        self.onClose = onClose
        self.onRoute = onRoute
        self.onBookmark = onBookmark
        self._isAddressExpanded = State(initialValue: initialAddressExpanded)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(preview.name)
                        .pretendard(.heading(.large))
                        .foregroundStyle(.gray5)
                    if preview.isMySpot {
                        mySpotBadge
                    }
                    Spacer(minLength: 0)

                    Button(action: onClose) {
                        Circle()
                            .fill(.white.opacity(0.15))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: "xmark")
                                    .imageScale(.small)
                                    .foregroundStyle(.gray0)
                            )
                    }
                }

                themeAndBookmarkRow
                distanceAndAddressRow
            }

            photoArea(imageURL: preview.imageUrl)
                .overlay(alignment: .top) {
                    if isAddressExpanded {
                        addressBox
                            .transition(.opacity)
                            .offset(y: -16)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if preview.imageUrl != nil {
                        isPhotoFullScreenPresented = true
                    }
                }
                .fullScreenCover(isPresented: $isPhotoFullScreenPresented) {
                    SpotPhotoFullScreenView(
                        imageURL: preview.imageUrl,
                        onClose: { isPhotoFullScreenPresented = false }
                    )
                }

            SpotBottomSheetActionButtons(
                isMine: preview.isMySpot,
                isBookmarked: isBookmarked,
                onRoute: onRoute,
                onBookmark: onBookmark
            )
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .overlay(alignment: .bottom) {
            if let copyToast {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.gray95)
                    Text(copyToast)
                        .pretendard(.body(.medium(.bold)))
                        .foregroundStyle(.gray95)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(.gray0)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 4)
                .padding(.bottom, 90)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
    }

    private var themeAndBookmarkRow: some View {
        HStack(spacing: 6) {
            Text(preview.theme.rawValue)
                .pretendard(.body(.medium(.regular)))
                .foregroundStyle(.gray10)
            if !preview.isMySpot {
                dotSeparator
                Text("북마크 \(preview.bookmarkCount)")
                    .pretendard(.body(.medium(.regular)))
                    .foregroundStyle(.gray10)
            }
        }
    }

    private var hasAnyAddress: Bool {
        !(preview.addressRoad?.isEmpty ?? true) || !(preview.addressJibun?.isEmpty ?? true)
    }

    private var distanceAndAddressRow: some View {
        HStack(spacing: 6) {
            Text(distanceText(preview.distanceKm))
                .pretendard(.body(.medium(.bold)))
                .foregroundStyle(.gray10)
            dotSeparator
            Button {
                guard hasAnyAddress else { return }
                withAnimation(.easeInOut(duration: 0.2)) { isAddressExpanded.toggle() }
            } label: {
                HStack(spacing: 0) {
                    Text(preview.addressSimple)
                        .pretendard(.body(.medium(.regular)))
                        .foregroundStyle(.gray0)
                    if hasAnyAddress {
                        Image(systemName: isAddressExpanded ? "chevron.up" : "chevron.down")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 10, height: 6)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 7)
                            .foregroundStyle(.gray10)
                    }
                }
            }
            Spacer(minLength: 0)
        }
    }

    private var dotSeparator: some View {
        Circle()
            .fill(UIAsset.Colors.gray50.swiftUIColor)
            .frame(width: 3, height: 3)
    }

    private func distanceText(_ distance: Double?) -> String {
        guard let distance else { return "-" }
        return String(format: "%.1fkm", distance)
    }

    private func copyAddress(_ value: String) {
        UIPasteboard.general.string = value
        withAnimation(.easeInOut(duration: 0.2)) { copyToast = "주소가 복사되었습니다." }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.easeInOut(duration: 0.2)) { copyToast = nil }
        }
    }

    private var addressBox: some View {
        VStack(alignment: .leading, spacing: 6) {
            addressLine(label: "도로명", value: preview.addressRoad)
            addressLine(label: "지번", value: preview.addressJibun)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.gray90)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.gray80, lineWidth: 1)
        )
    }

    private func addressLine(label: String, value: String?) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .pretendard(.body(.small(.regular)))
                .foregroundStyle(.gray30)
            if let value, !value.isEmpty {
                Text(value)
                    .pretendard(.body(.small(.regular)))
                    .foregroundStyle(.gray0)
                Button {
                    copyAddress(value)
                } label: {
                    Text("복사")
                        .pretendard(.body(.small(.bold)))
                        .foregroundStyle(.sunsetOrange)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            } else {
                Text("-")
                    .pretendard(.body(.small(.regular)))
                    .foregroundStyle(.gray0)
            }
        }
    }

    @ViewBuilder
    private func photoArea(imageURL: String?) -> some View {
        AsyncImage(url: imageURL.flatMap(URL.init(string:))) { phase in
            switch phase {
            case let .success(image):
                image.resizable().scaledToFill()
            default:
                UIAsset.Colors.gray90.swiftUIColor
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .clipped()                           // scaledToFill 오버플로 영역을 hit 까지 자른다
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())           // hit shape 명시 (외부 제스처 침범 방지)
    }

    private var mySpotBadge: some View {
        Text("MY 스팟")
            .pretendard(.body(.small(.bold)))
            .foregroundStyle(.sunsetOrange)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(.sunsetOrange, lineWidth: 1)
            )
    }
}

#if DEBUG
#Preview("Medium Sheet") {
    @Previewable @StateObject var viewModel = SpotDetailDebugFactory.makeViewModel(spotId: 1)

    ZStack(alignment: .bottom) {
        Color.black.opacity(0.4).ignoresSafeArea()
        SpotShellRootView(viewModel: viewModel)
            .frame(maxHeight: UIScreen.main.bounds.height * 0.55)
    }
    .preferredColorScheme(.dark)
}

#Preview("Medium Sheet — 주소 펼침/저장됨") {
    ZStack(alignment: .bottom) {
        Color.black.opacity(0.4).ignoresSafeArea()
        SheetChromeView {
            SpotDetailSheetContentView(
                preview: SpotDetailDebugFixture.preview,
                isBookmarked: true,
                initialAddressExpanded: true
            )
        }
        .frame(maxHeight: UIScreen.main.bounds.height * 0.55)
    }
    .preferredColorScheme(.dark)
}
#endif
