import SwiftUI

enum DummyRoute: Hashable {
    case detail(from: String)
}

struct DetailDummyView: View {
    let route: DummyRoute

    var body: some View {
        VStack(spacing: 16) {
            Text("2 Depth")
                .pretendard(.display(.medium))
                .foregroundStyle(.gray95)

            Text(captionText)
                .pretendard(.body(.medium()))
                .foregroundStyle(.gray60)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.gray0)
        .navigationTitle("Detail")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var captionText: String {
        switch route {
        case .detail(let from):
            "\(from) 탭에서 push된 더미 화면입니다.\nCustomTabBar가 사라지는지 확인하세요."
        }
    }
}

#Preview {
    NavigationStack {
        DetailDummyView(route: .detail(from: "탐색"))
    }
}
