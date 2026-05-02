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
                .pretendard(.body(.medium(.bold)))
                .foregroundStyle(.white)
                .textInputAutocapitalization(.words)

                HStack(spacing: 0) {
                    Text("\(count)")
                        .foregroundStyle(.white)
                    Text("/\(maxCount)")
                        .foregroundStyle(Color.spotSecondaryText)
                }
                    .pretendard(.label(.medium))
                    .accessibilityLabel("\(count)자, 최대 \(maxCount)자")
            }
            .padding(16)
            .frame(height: 56)
            .background(Color.spotInputBackground, in: RoundedRectangle(cornerRadius: 8))
            .accessibilityElement(children: .contain)
            .accessibilityLabel(title)
        }
    }
}
