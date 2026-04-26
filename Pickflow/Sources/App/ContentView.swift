import SwiftUI
import UIKit

struct ContentView: View {
    @State private var isSpotDetailPresented = false
    private let debugSpotId: Int64 = 1

    var body: some View {
        VStack(spacing: 16) {
            Text("Pickflow")
                .font(.largeTitle)

            Button("Spot Detail 열기") {
                isSpotDetailPresented = true
            }
        }
        .fullScreenCover(isPresented: $isSpotDetailPresented) {
#if DEBUG
            // TODO: KAN-51 API 사용 가능해지면 실제 DI 서비스 주입으로 되돌리기
            SpotDetailView(viewModel: SpotDetailDebugFactory.makeViewModel(spotId: debugSpotId))
#else
            SpotDetailView(
                viewModel: SpotDetailViewModel(
                    spotId: debugSpotId,
                    spotService: getSpotService(),
                    bookmarkService: getBookmarkService(),
                    shareIntentService: getShareIntentService(),
                    locationService: getLocationService(),
                    externalAppLauncher: getExternalAppLauncher(),
                    shareSheetPresenter: getShareSheetPresenter(),
                    deviceIdProvider: { UIDevice.current.identifierForVendor?.uuidString ?? "unknown-device" }
                )
            )
#endif
        }
    }
}

#Preview {
    ContentView()
}
