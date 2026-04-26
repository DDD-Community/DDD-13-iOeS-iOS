import SwiftUI

enum MapListMode: String {
    case map = "지도"
    case list = "리스트"
}

struct MapListToggle: View {
    @Binding var selectedMode: MapListMode
    private let items: [MapListMode] = [.map, .list]

    @Namespace private var indicatorWE

    var body: some View {
        VStack(spacing: 20) {

            HStack(spacing: 0) {
                ForEach(items, id: \.self) { item in
                    segmentButton(with: item)
                }
            }
            .padding(6)  // 바깥 캡슐과 선택 캡슐 사이 여백
            .frame(width: 172, height: 49)
            .background(
                Capsule()
                    .fill(.gray95)
            )
        }
    }

    private func segmentButton(with mode: MapListMode) -> some View {
        Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                selectedMode = mode
            }
        } label: {
            ZStack {
                if selectedMode == mode {
                    Capsule()
                        .fill(selectedMode == mode ? .gray5 : .gray95)
                        .matchedGeometryEffect(id: "pickflow.segment.indicator", in: indicatorWE)
                }

                Text(mode.rawValue)
                    .pretendard(.body(.medium(.bold)))
                    .foregroundStyle(selectedMode == mode ? .gray95 : .gray40)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 20)
            }
        }
    }
}

#Preview {
    HomeMapView()
}
