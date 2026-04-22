import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Pickflow")
                    .pretendard(.display(.medium))

                NavigationLink("스팟 등록 열기") {
                    SpotRegistrationAssembly.make()
                }
                .pretendard(.body(.large(.bold)))
            }
        }
    }
}

#Preview {
    ContentView()
}
