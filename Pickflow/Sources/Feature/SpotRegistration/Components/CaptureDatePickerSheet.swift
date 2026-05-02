import SwiftUI

struct CaptureDatePickerSheet: View {
    let initialDate: Date?
    let onConfirm: (Date) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selectedYear: Int
    @State private var selectedMonth: Int
    @State private var selectedDay: Int

    private let calendar = Calendar.spotRegistrationGregorian
    private let now: Date

    init(initialDate: Date?, onConfirm: @escaping (Date) -> Void) {
        self.initialDate = initialDate
        self.onConfirm = onConfirm

        let now = Date()
        self.now = now

        let seedDate = initialDate ?? now
        let components = Calendar.spotRegistrationGregorian.dateComponents([.year, .month, .day], from: min(seedDate, now))
        _selectedYear = State(initialValue: components.year ?? 2000)
        _selectedMonth = State(initialValue: components.month ?? 1)
        _selectedDay = State(initialValue: components.day ?? 1)
    }

    private var availableYears: [Int] {
        let currentYear = calendar.component(.year, from: now)
        return Array(2000...currentYear)
    }

    private var availableMonths: [Int] {
        let currentYear = calendar.component(.year, from: now)
        let upperBound = selectedYear == currentYear ? calendar.component(.month, from: now) : 12
        return Array(1...upperBound)
    }

    private var availableDays: [Int] {
        let currentYear = calendar.component(.year, from: now)
        let currentMonth = calendar.component(.month, from: now)
        let fullRange = calendar.range(of: .day, in: .month, for: selectedMonthDate) ?? 1..<32
        let upperBound = selectedYear == currentYear && selectedMonth == currentMonth
            ? min(fullRange.upperBound - 1, calendar.component(.day, from: now))
            : fullRange.upperBound - 1
        return Array(1...upperBound)
    }

    private var selectedMonthDate: Date {
        var components = DateComponents()
        components.year = selectedYear
        components.month = selectedMonth
        components.day = 1
        return calendar.date(from: components) ?? now
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("날짜 선택")
                .pretendard(.heading(.small))
                .foregroundStyle(.white)

            HStack(spacing: 0) {
                wheelPicker(values: availableYears, selection: $selectedYear) { value in
                    "\(value)년"
                }
                wheelPicker(values: availableMonths, selection: $selectedMonth) { value in
                    "\(value)월"
                }
                wheelPicker(values: availableDays, selection: $selectedDay) { value in
                    "\(value)일"
                }
            }
            .frame(height: 180)

            Button {
                onConfirm(confirmedDate)
                dismiss()
            } label: {
                Text("확인")
                    .pretendard(.body(.large(.bold)))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(Color.spotOrange, in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
        }
        .padding(.top, 24)
        .padding(.bottom, 48)
        .background(Color.spotCardBackground)
        .environment(\.colorScheme, .dark)
        .presentationDetents([.height(360)])
        .presentationBackground(Color.spotCardBackground)
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(16)
        .onChange(of: selectedYear) { _, _ in
            clampMonthAndDay()
        }
        .onChange(of: selectedMonth) { _, _ in
            clampDay()
        }
        // TODO(design-polish): 커스텀 wheel 스타일과 선택 영역 하이라이트 반영
    }

    private var confirmedDate: Date {
        var components = DateComponents()
        components.year = selectedYear
        components.month = selectedMonth
        components.day = selectedDay
        let date = calendar.date(from: components) ?? now
        return min(calendar.startOfDay(for: date), calendar.startOfDay(for: now))
    }

    private func clampMonthAndDay() {
        if !availableMonths.contains(selectedMonth), let lastMonth = availableMonths.last {
            selectedMonth = lastMonth
        }

        clampDay()
    }

    private func clampDay() {
        if !availableDays.contains(selectedDay), let lastDay = availableDays.last {
            selectedDay = lastDay
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
                    .foregroundStyle(.white)
                    .tag(value)
            }
        }
        .pickerStyle(.wheel)
        .frame(maxWidth: .infinity)
        .clipped()
    }
}
