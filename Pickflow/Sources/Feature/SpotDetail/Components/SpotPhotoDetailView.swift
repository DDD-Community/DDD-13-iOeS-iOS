import SwiftUI
import UIKit

struct SpotPhotoDetailView: View {
    let imageURL: String?
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let urlString = imageURL, let url = URL(string: urlString) {
                ZoomableImageView(url: url)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
            }
            .padding(.top, 8)
            .padding(.trailing, 8)
        }
    }
}

struct ZoomableImageView: UIViewRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.delegate = context.coordinator
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.backgroundColor = .black
        scrollView.bouncesZoom = true

        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .black
        scrollView.addSubview(imageView)

        context.coordinator.imageView = imageView
        context.coordinator.scrollView = scrollView
        context.coordinator.loadImage(from: url)

        let doubleTap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleDoubleTap(_:))
        )
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)

        return scrollView
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {}

    final class Coordinator: NSObject, UIScrollViewDelegate {
        weak var imageView: UIImageView?
        weak var scrollView: UIScrollView?
        private var loadedURL: URL?

        func loadImage(from url: URL) {
            guard loadedURL != url else { return }
            loadedURL = url
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let (data, _) = try? await URLSession.shared.data(from: url),
                   let image = UIImage(data: data) {
                    self.imageView?.image = image
                    self.layoutImageView()
                }
            }
        }

        func layoutImageView() {
            guard let scrollView, let imageView, let image = imageView.image else { return }
            let boundsSize = scrollView.bounds.size
            guard boundsSize.width > 0, boundsSize.height > 0 else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                    self?.layoutImageView()
                }
                return
            }
            scrollView.zoomScale = 1.0
            let scale = min(boundsSize.width / image.size.width,
                            boundsSize.height / image.size.height)
            let scaledSize = CGSize(width: image.size.width * scale,
                                    height: image.size.height * scale)
            imageView.frame = CGRect(origin: .zero, size: scaledSize)
            scrollView.contentSize = scaledSize
            centerContent(in: scrollView)
        }

        private func centerContent(in scrollView: UIScrollView) {
            let boundsSize = scrollView.bounds.size
            let contentSize = scrollView.contentSize
            let top = max(0, (boundsSize.height - contentSize.height) / 2)
            let left = max(0, (boundsSize.width - contentSize.width) / 2)
            scrollView.contentInset = UIEdgeInsets(top: top, left: left, bottom: top, right: left)
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            imageView
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            centerContent(in: scrollView)
        }

        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            guard let scrollView = gesture.view as? UIScrollView else { return }
            if scrollView.zoomScale > 1.0 {
                scrollView.setZoomScale(1.0, animated: true)
            } else {
                let point = gesture.location(in: imageView)
                scrollView.zoom(to: CGRect(x: point.x, y: point.y, width: 1, height: 1), animated: true)
            }
        }
    }
}
