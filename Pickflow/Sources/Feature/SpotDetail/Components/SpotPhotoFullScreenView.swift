import SwiftUI

struct SpotPhotoFullScreenView: View {
    let imageURL: String?
    let onClose: () -> Void

    @State private var scale: CGFloat = 1.0
    @State private var gestureScale: CGFloat = 1.0
    @State private var anchor: UnitPoint = .center

    private let minScale: CGFloat = 1.0
    private let maxScale: CGFloat = 3.0
    private let doubleTapScale: CGFloat = 1.5

    var body: some View {
        ZStack {
            Color("gray100").ignoresSafeArea()

            GeometryReader { proxy in
                imageContent
                    .scaleEffect(scale * gestureScale, anchor: anchor)
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .contentShape(Rectangle())
                    .gesture(magnifyGesture)
                    .gesture(doubleTapGesture(in: proxy.size))
            }

            VStack {
                HStack {
                    Spacer()
                    Button(action: onClose) {
                        AssetImage(named: "icXClose", size: 24) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.gray0)
                        }
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                    }
                }
                .padding(.horizontal, 8)
                Spacer()
            }
        }
    }

    @ViewBuilder
    private var imageContent: some View {
        AsyncImage(url: imageURL.flatMap(URL.init(string:))) { phase in
            switch phase {
            case let .success(image):
                image
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failure:
                Color.clear
            default:
                ProgressView().tint(UIAsset.Colors.gray0.swiftUIColor)
            }
        }
    }

    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                gestureScale = value.magnification
            }
            .onEnded { value in
                let next = (scale * value.magnification).clamped(to: minScale...maxScale)
                scale = next
                gestureScale = 1.0
                if scale == minScale { anchor = .center }
            }
    }

    private func doubleTapGesture(in size: CGSize) -> some Gesture {
        SpatialTapGesture(count: 2)
            .onEnded { value in
                withAnimation(.easeInOut(duration: 0.25)) {
                    if scale > minScale {
                        scale = minScale
                        anchor = .center
                    } else {
                        let unitX = size.width > 0 ? value.location.x / size.width : 0.5
                        let unitY = size.height > 0 ? value.location.y / size.height : 0.5
                        anchor = UnitPoint(x: unitX, y: unitY)
                        scale = doubleTapScale
                    }
                }
            }
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

#if DEBUG
#Preview {
    SpotPhotoFullScreenView(
        imageURL: "https://picsum.photos/800/1200",
        onClose: {}
    )
    .preferredColorScheme(.dark)
}
#endif
