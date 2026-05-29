import SwiftUI
import UIKit

struct SpotMarkerView: View {
    let isSelected: Bool
    var image: UIImage? = nil

    private let diameter: CGFloat = 44

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: diameter, height: diameter)
                    .clipShape(Circle())
            }
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.black.opacity(0), .black.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            if image == nil {
                Image(.icPhoto)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
            }
        }
        .frame(width: diameter, height: diameter)
        .overlay {
            if isSelected {
                Circle()
                    .strokeBorder(Color(.sunsetOrange), lineWidth: 4)
            }
        }
    }
}
