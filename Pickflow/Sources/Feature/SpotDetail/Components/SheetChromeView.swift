import SwiftUI

// grab handle은 SpotPresentationController가 UIKit 측에서 그린다.
// SwiftUI 측에서는 콘텐츠 padding + 시트 배경/코너만 책임진다.
struct SheetChromeView<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(.top, 24)
            .background(.gray95)
            .clipShape(.rect(topLeadingRadius: 20, topTrailingRadius: 20))
    }
}
