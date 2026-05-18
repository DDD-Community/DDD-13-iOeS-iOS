import SwiftUI

struct SheetChromeView<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Capsule()
                    .fill(.sheetGrabHandle)
                    .frame(width: 45, height: 3)
                Spacer()
            }
            .padding(.vertical, 8)
            content()
                .padding(.top, 16)
        }
        .background(.gray95)
        .clipShape(.rect(topLeadingRadius: 20, topTrailingRadius: 20))
    }
}

private extension ShapeStyle where Self == Color {
    static var sheetGrabHandle: Color {
        Color(red: 0xD9 / 255, green: 0xD9 / 255, blue: 0xD9 / 255)
    }
}
