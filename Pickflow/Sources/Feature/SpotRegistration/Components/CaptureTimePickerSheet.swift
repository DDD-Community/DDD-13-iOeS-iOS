import SwiftUI

struct CaptureTimePickerSheet: View {
    let selectedDate: Date?
    let initialTime: Date?
    let onConfirm: (Date) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selectedHour24: Int
    @State private var selectedMinute: Int

    private let calendar = Calendar.spotRegistrationGregorian
    private let now: Date

    init(selectedDate: Date?, initialTime: Date?, onConfirm: @escaping (Date) -> Void) {
        self.selectedDate = selectedDate
        self.initialTime = initialTime
        self.onConfirm = onConfirm

        let now = Date()
        self.now = now

        let seed = min(initialTime ?? now, now)
        let components = Calendar.spotRegistrationGregorian.dateComponents([.hour, .minute], from: seed)
        _selectedHour24 = State(initialValue: components.hour ?? 0)
        _selectedMinute = State(initialValue: components.minute ?? 0)
    }

    private var isTodaySelection: Bool {
        guard let selectedDate else { return true }
        return calendar.isDate(selectedDate, inSameDayAs: now)
    }

    private var maxHour24: Int {
        isTodaySelection ? calendar.component(.hour, from: now) : 23
    }

    private var maxMinute: Int {
        isTodaySelection && selectedHour24 == maxHour24 ? calendar.component(.minute, from: now) : 59
    }

    private var meridiemBinding: Binding<Int> {
        Binding(
            get: { selectedHour24 >= 12 ? 1 : 0 },
            set: { newValue in
                let hour12 = ((selectedHour24 + 11) % 12) + 1
                let baseHour = hour12 % 12
                selectedHour24 = newValue == 1 ? baseHour + 12 : baseHour
                clampSelectionIfNeeded()
            }
        )
    }

    private var hour12Binding: Binding<Int> {
        Binding(
            get: { ((selectedHour24 + 11) % 12) + 1 },
            set: { newValue in
                let isPM = selectedHour24 >= 12
                let baseHour = newValue % 12
                selectedHour24 = isPM ? baseHour + 12 : baseHour
                clampSelectionIfNeeded()
            }
        )
    }

    var body: some View {
        VStack(spacing: 20) {
            Capsule()
                .fill(Color.white.opacity(0.18))
                .frame(width: 44, height: 5)
                .padding(.top, 8)

            Text("시간 선택")
                .pretendard(.body(.large(.bold)))
                .foregroundStyle(.white)

            HStack(spacing: 0) {
                wheelPicker(values: [0, 1], selection: meridiemBinding) { value in
                    value == 0 ? "오전" : "오후"
                }
                wheelPicker(values: Array(1...12), selection: hour12Binding) { value in
                    "\(value)시"
                }
                wheelPicker(values: Array(0...maxMinute), selection: $selectedMinute) { value in
                    String(format: "%02d분", value)
                }
            }
            .frame(height: 180)

            Button {
                onConfirm(confirmedTime)
                dismiss()
            } label: {
                Text("확인")
                    .pretendard(.body(.large(.bold)))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .background(Color.spotOrange, in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color.spotCardBackground)
        .presentationDetents([.height(360)])
        .presentationDragIndicator(.visible)
        .onChange(of: selectedHour24) { _, _ in
            clampSelectionIfNeeded()
        }
        // TODO(design-polish): 커스텀 wheel 스타일과 선택 영역 하이라이트 반영
    }

    private var confirmedTime: Date {
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = min(selectedHour24, maxHour24)
        components.minute = min(selectedMinute, maxMinute)
        return calendar.date(from: components) ?? now
    }

    private func clampSelectionIfNeeded() {
        if selectedHour24 > maxHour24 {
            selectedHour24 = maxHour24
        }

        if selectedMinute > maxMinute {
            selectedMinute = maxMinute
        }
    }

    private func wheelPicker<Value: Hashable>(
        values: [Value],
        selection: Binding<Value>,
        title: @escaping (Value) -> String
    ) -> some View {
        Picker("", selection: selection) {
            ForEach(values, id: \.self) { value in
                Text(title(value))
                    .pretendard(.body(.large()))
                    .foregroundStyle(.white)
                    .tag(value)
            }
        }
        .pickerStyle(.wheel)
        .frame(maxWidth: .infinity)
        .clipped()
    }
}
