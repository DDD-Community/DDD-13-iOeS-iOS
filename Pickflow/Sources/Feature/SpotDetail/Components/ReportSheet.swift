import SwiftUI

struct ReportSheet: View {
    let onDismiss: () -> Void
    let onSubmit: (String) -> Void

    @State private var text = ""
    private let maxLength = 200
    private let minLength = 5
    private let placeholder = "실제 위치가 지도와 달라요, 현재 공사 중이라 출입이 안 돼요 등 상세한 내용을 적어주세요 (최소 5자 이상)"

    var body: some View {
        let isSubmittable = text.trimmingCharacters(in: .whitespacesAndNewlines).count >= minLength

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
                        .foregroundStyle(isSubmittable ? .sunsetOrange : .gray50)
                }
                .disabled(!isSubmittable)
            }
            .padding(.horizontal, 20)
            .padding(.top, 36)
            .padding(.bottom, 20)

            ZStack(alignment: .bottomTrailing) {
                ZStack(alignment: .topLeading) {
                    if text.isEmpty {
                        Text(placeholder)
                            .pretendard(.body(.medium()))
                            .foregroundStyle(.gray50)
                            .padding(.top, 8)
                            .padding(.leading, 5)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $text)
                        .pretendard(.body(.medium()))
                        .foregroundStyle(.gray0)
                        .scrollContentBackground(.hidden)
                        .onChange(of: text) { _, newValue in
                            if newValue.count > maxLength {
                                text = String(newValue.prefix(maxLength))
                            }
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
