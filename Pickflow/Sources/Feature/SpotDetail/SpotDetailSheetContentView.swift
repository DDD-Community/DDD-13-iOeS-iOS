import SwiftUI

struct SpotDetailSheetContentView: View {
    let spot: SpotDetail
    let isBookmarked: Bool
    @State private var isAddressExpanded: Bool

    init(spot: SpotDetail, isBookmarked: Bool, initialAddressExpanded: Bool = false) {
        self.spot = spot
        self.isBookmarked = isBookmarked
        self._isAddressExpanded = State(initialValue: initialAddressExpanded)
    }

    var body: some View {
        content(spot: spot)
    }

    @ViewBuilder
    private func content(spot: SpotDetail) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
              HStack {
                Text(spot.name)
                    .pretendard(.heading(.large))
                    .foregroundStyle(.gray5)
                Spacer(minLength: 0)
                
                Button(action: {}) {
                  Circle()
                    .fill(.white.opacity(0.15))
                    .overlay(
                      Image(systemName: "xmark")
                        .imageScale(.small)
                        .foregroundStyle(.gray0)
                    )
                }
              }
                
                themeAndBookmarkRow(spot: spot)
                distanceAndAddressRow(spot: spot)
            }
            
            photoArea(imageURL: spot.primaryImage?.imageURL)
            .overlay(alignment: .top, content: {
              if isAddressExpanded {
                  addressBox(spot: spot)
                  .transition(.opacity)
                      .offset(y: -16)
              }
            })
            
            actionRow(isBookmarked: isBookmarked)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 60)
    }

    @ViewBuilder
    private func themeAndBookmarkRow(spot: SpotDetail) -> some View {
        HStack(spacing: 6) {
            Text(spot.theme.rawValue)
                .pretendard(.body(.medium(.regular)))
                .foregroundStyle(.gray10)
            dotSeparator
            Text("북마크 \(spot.bookmarkCount)")
                .pretendard(.body(.medium(.regular)))
                .foregroundStyle(.gray10)
        }
    }

    @ViewBuilder
    private func distanceAndAddressRow(spot: SpotDetail) -> some View {
        HStack(spacing: 6) {
            Text(distanceText(spot.distance))
                .pretendard(.body(.medium(.bold)))
                .foregroundStyle(.gray10)
            dotSeparator
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { isAddressExpanded.toggle() }
            } label: {
                HStack(spacing: 0) {
                    Text(spot.address)
                        .pretendard(.body(.medium(.regular)))
                        .foregroundStyle(.gray0)
                    Image(systemName: isAddressExpanded ? "chevron.up" : "chevron.down")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 10, height: 6)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 7)
                        .foregroundStyle(.gray10)
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

    @ViewBuilder
    private func addressBox(spot: SpotDetail) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            addressLine(label: "도로명", value: spot.address)
            addressLine(label: "지번", value: spot.address)
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

    @ViewBuilder
    private func addressLine(label: String, value: String) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .pretendard(.body(.small(.regular)))
                .foregroundStyle(.gray30)
            Text(value)
                .pretendard(.body(.small(.regular)))
                .foregroundStyle(.gray0)
            Text("복사")
                .pretendard(.body(.small(.bold)))
                .foregroundStyle(.sunsetOrange)
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
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private func actionRow(isBookmarked: Bool) -> some View {
        HStack(spacing: 12) {
            Button {} label: {
                HStack(spacing: 8) {
                    Image(systemName: "location.north.fill")
                        .resizable()
                        .rotationEffect(Angle.degrees(45))
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundStyle(UIAsset.Colors.gray0.swiftUIColor)
                    Text("길 안내 받기")
                        .pretendard(.body(.large(.bold)))
                        .foregroundStyle(UIAsset.Colors.gray0.swiftUIColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
            }
            .background(UIAsset.Colors.sunsetOrange.swiftUIColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Button {} label: {
                HStack(spacing: 8) {
                  Image(isBookmarked ? .icBookmarkFilled : .icBookmarkBorder)
                        .scaledToFit()
                        .foregroundStyle(.gray80)
                    Text(isBookmarked ? "저장됨" : "저장하기")
                        .pretendard(.body(.large(.bold)))
                        .foregroundStyle(.gray80)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
            }
            .background(.gray0)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
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
    @Previewable @StateObject var viewModel = SpotDetailDebugFactory.makeViewModel(spotId: 1)

    ZStack(alignment: .bottom) {
        Color.black.opacity(0.4).ignoresSafeArea()
        SheetChromeView {
            SpotDetailSheetContentView(
                spot: SpotDetailDebugFixture.spot,
                isBookmarked: true,
                initialAddressExpanded: true
            )
        }
        .frame(maxHeight: UIScreen.main.bounds.height * 0.55)
    }
    .preferredColorScheme(.dark)
}
#endif
