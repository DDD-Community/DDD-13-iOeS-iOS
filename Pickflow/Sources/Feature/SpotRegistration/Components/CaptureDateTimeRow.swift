import SwiftUI

struct CaptureDateTimeRow: View {
    let dateText: String?
    let timeText: String?
    @Binding var isDateSheetPresented: Bool
    @Binding var isTimeSheetPresented: Bool

    var body: some View {
        LabeledSection(title: "촬영 기록 정보") {
            HStack(spacing: 12) {
                selectionField(
                    title: "날짜 선택",
                    value: dateText,
                    action: { isDateSheetPresented = true }
                )
                .accessibilityLabel(dateText == nil ? "촬영 날짜 선택" : "촬영 날짜 \(dateText!)")

                selectionField(
                    title: "시간 선택",
                    value: timeText,
                    action: { isTimeSheetPresented = true }
                )
                .accessibilityLabel(timeText == nil ? "촬영 시간 선택" : "촬영 시간 \(timeText!)")
            }
        }
    }

    private func selectionField(title: String, value: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(value ?? title)
                    .pretendard(.body(.medium(.bold)))
                    .foregroundStyle(value == nil ? Color.spotSecondaryText : .white)

                Spacer(minLength: 0)

                if value != nil {
                    Text("수정")
                        .pretendard(.label(.medium))
                        .foregroundStyle(Color.spotOrange)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            .padding(.horizontal, 16)
            .background(Color.spotPhotoCardBackground, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
