import SwiftUI

struct CountedTextEditor: View {
    let title: String
    let placeholder: String
    let text: Binding<String>
    let count: Int
    let maxCount: Int

    var body: some View {
        LabeledSection(title: title) {
            VStack(alignment: .trailing, spacing: 8) {
                ZStack(alignment: .topLeading) {
                    if text.wrappedValue.isEmpty {
                        Text(placeholder)
                            .pretendard(.body(.medium(.bold)))
                            .foregroundStyle(Color.spotSecondaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .allowsHitTesting(false)
                    }

                    TextField("", text: text, axis: .vertical)
                        .pretendard(.body(.medium(.bold)))
                        .foregroundStyle(.white)
                        .textInputAutocapitalization(.sentences)
                        .lineLimit(4...6)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(minHeight: 64, alignment: .topLeading)

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
            .background(Color.spotInputBackground, in: RoundedRectangle(cornerRadius: 8))
            .accessibilityElement(children: .contain)
            .accessibilityLabel(title)
        }
    }
}
