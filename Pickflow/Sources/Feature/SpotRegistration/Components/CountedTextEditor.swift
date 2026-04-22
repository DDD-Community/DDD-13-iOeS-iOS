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
                            .pretendard(.body(.large()))
                            .foregroundStyle(Color.spotSecondaryText)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 8)
                            .allowsHitTesting(false)
                    }

                    TextField("", text: text, axis: .vertical)
                        .pretendard(.body(.large()))
                        .foregroundStyle(.white)
                        .textInputAutocapitalization(.sentences)
                        .lineLimit(4...6)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(minHeight: 96, alignment: .topLeading)

                Text("\(count)/\(maxCount)")
                    .pretendard(.label(.small))
                    .foregroundStyle(Color.spotSecondaryText)
                    .accessibilityLabel("\(count)자, 최대 \(maxCount)자")
            }
            .padding(12)
            .background(Color.spotCardBackground, in: RoundedRectangle(cornerRadius: 16))
            .accessibilityElement(children: .contain)
            .accessibilityLabel(title)
        }
    }
}
