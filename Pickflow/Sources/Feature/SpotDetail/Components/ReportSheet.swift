import SwiftUI

struct ReportSheet: View {
    let onDismiss: () -> Void
    let onSubmit: (String) -> Void

    @State private var text = ""
    private let maxLength = 200

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onDismiss) {
                    AssetImage(named: "icClose", size: 24) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(.gray0)
                    }
                }
                Spacer()
                Text("잘못된 정보가 있나요?")
                    .pretendard(.body(.large(.bold)))
                    .foregroundStyle(.gray0)
                Spacer()
                Button {
                    onSubmit(text)
                } label: {
                    Text("등록")
                        .pretendard(.body(.large(.bold)))
                        .foregroundStyle(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray50 : .sunsetOrange)
                }
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)

            ZStack(alignment: .bottomTrailing) {
                TextEditor(text: $text)
                    .pretendard(.body(.medium()))
                    .foregroundStyle(.gray0)
                    .scrollContentBackground(.hidden)
                    .onChange(of: text) { _, newValue in
                        if newValue.count > maxLength {
                            text = String(newValue.prefix(maxLength))
                        }
                    }

                HStack(spacing: 0) {
                    Text("\(text.count)")
                        .foregroundStyle(.gray0)
                    Text("/\(maxLength)")
                        .foregroundStyle(.gray50)
                }
                .pretendard(.body(.small()))
                .padding(12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(16)
            .background(UIAsset.Colors.gray90.swiftUIColor)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
}
