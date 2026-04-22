import SwiftUI

struct SpotDetailPlaceholderView: View {
    let spotId: SpotId

    var body: some View {
        ZStack {
            Color.spotBackground
                .ignoresSafeArea()

            Text("Spot Detail (WIP) - id: \(spotId.rawValue)")
                .pretendard(.body(.large(.bold)))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(24)
        }
        .navigationTitle("스팟 상세")
        .navigationBarTitleDisplayMode(.inline)
    }
}
