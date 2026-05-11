import SwiftUI

struct SpotMarkerView: View {
    let isSelected: Bool

    private let diameter: CGFloat = 44

    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [.black.opacity(0), .black.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay {
                Image(.icPhoto)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
            }
            .overlay {
                if isSelected {
                    Circle()
                        .strokeBorder(Color(.sunsetOrange), lineWidth: 4)
                }
            }
            .frame(width: diameter, height: diameter)
    }
}
