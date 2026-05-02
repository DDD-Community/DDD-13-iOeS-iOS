import SwiftUI

struct LabeledSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .pretendard(.body(.small(.bold)))
                .foregroundStyle(.white)

            content
        }
    }
}
