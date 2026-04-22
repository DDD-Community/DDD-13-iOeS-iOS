import SwiftUI

struct CountedTextField: View {
    let title: String
    let placeholder: String
    let text: Binding<String>
    let count: Int
    let maxCount: Int

    var body: some View {
        LabeledSection(title: title) {
            HStack(spacing: 12) {
                TextField(
                    "",
                    text: text,
                    prompt: Text(placeholder)
                        .foregroundStyle(Color.spotSecondaryText)
                )
                .pretendard(.body(.large()))
                .foregroundStyle(.white)
                .textInputAutocapitalization(.words)

                Text("\(count)/\(maxCount)")
                    .pretendard(.label(.small))
                    .foregroundStyle(Color.spotSecondaryText)
                    .accessibilityLabel("\(count)자, 최대 \(maxCount)자")
            }
            .padding(.horizontal, 16)
            .frame(height: 48)
            .background(Color.spotCardBackground, in: RoundedRectangle(cornerRadius: 16))
            .accessibilityElement(children: .contain)
            .accessibilityLabel(title)
        }
    }
}
