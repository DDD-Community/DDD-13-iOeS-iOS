import SwiftUI
import UIKit

/// my spot 단일 마커. 큐레이션 클러스터링에 참여하지 않고 항상 단일로 표시되는 디자인.
/// 회색 그라데이션(검정 → 흰색 톤) 배경 + 사진 아이콘 + "MY" 텍스트.
struct MyClusterPinView: View {
    static let diameter: CGFloat = 56
    var isSelected: Bool = false
    var image: UIImage? = nil

    var body: some View {
        ZStack {
          circleBackground
          if let image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: Self.diameter, height: Self.diameter)
                .clipShape(Circle())
          }
          rectangle125
          content
        }
        .overlay {
          if isSelected {
            Circle().strokeBorder(Color(.sunsetOrange), lineWidth: 4)
          }
        }
        .frame(width: Self.diameter, height: Self.diameter)
    }

  /// Figma [Clustering]: 흰색(#FFFFFF) + 검정 alpha 0.2 오버레이 + drop shadow.
  var circleBackground: some View {
    Circle()
        .fill(.white)
        .overlay(
          Circle().fill(.black.opacity(0.2))
        )
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 4)
  }

  /// Figma [Rectangle 125]: linear-gradient(180deg, rgba(0,0,0,0) 30%, rgba(0,0,0,0.7) 100%).
  var rectangle125: some View {
    Circle()
        .fill(
          LinearGradient(
            stops: [
              .init(color: .black.opacity(0), location: 0.30),
              .init(color: .black.opacity(0.7), location: 1.0),
            ],
            startPoint: .top,
            endPoint: .bottom
          )
        )
  }
  
  var content: some View {
    VStack(spacing: 0) {
          Image(.icPhoto)
              .resizable()
              .scaledToFit()
              .frame(width: 18, height: 18)
              .opacity(image == nil ? 0.5 : 0)
              .padding(10)
              .overlay(alignment: .bottom, content: {
                Text("MY")
                    .pretendard(.body(.small(.bold)))
                    .foregroundStyle(.gray0)
              })
      }
  }
}

#Preview {
  MyClusterPinView()
}
