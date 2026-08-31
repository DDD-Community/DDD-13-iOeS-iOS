import SwiftUI

/// 지역(대전/서울) 선택 바텀시트. [적용하기]를 눌러야만 확정되고, 취소/바깥 탭/스와이프 dismiss는
/// pending 선택을 폐기한다(§2.2 바텀시트 동작 원칙).
struct RegionSelectionSheet: View {
    let regions: [Region]
    let appliedRegion: Region?
    let onApply: (Region) -> Void
    let onCancel: () -> Void

    @State private var pendingRegion: Region?

    init(
        regions: [Region],
        appliedRegion: Region?,
        onApply: @escaping (Region) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.regions = regions
        self.appliedRegion = appliedRegion
        self.onApply = onApply
        self.onCancel = onCancel
        _pendingRegion = State(initialValue: appliedRegion)
    }

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("어느 지역을 둘러볼까요?")
                    .pretendard(.heading(.small))
                    .foregroundStyle(.gray0)
                Text("선택한 지역을 기준으로 스팟을 보여드려요.")
                    .pretendard(.body(.medium()))
                    .foregroundStyle(.gray50)
            }
            .padding(.top, 8)

            VStack(spacing: 8) {
                ForEach(regions) { region in
                    row(region)
                }
            }

            HStack(spacing: 8) {
                Button(action: onCancel) {
                    Text("취소")
                        .pretendard(.body(.large(.bold)))
                        .foregroundStyle(.gray80)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                }
                .background(.gray0)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Button {
                    guard let pendingRegion else { return }
                    onApply(pendingRegion)
                } label: {
                    Text("적용하기")
                        .pretendard(.body(.large(.bold)))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                }
                .background(.sunsetOrange)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .disabled(pendingRegion == nil)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 20)
        .presentationDetents([.height(392)])
        .presentationBackground(UIAsset.Colors.surfaceModal.swiftUIColor)
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(20)
    }

    private func row(_ region: Region) -> some View {
        let isSelected = region == pendingRegion
        return Button {
            pendingRegion = region
        } label: {
            HStack {
                Text(region.name)
                    .pretendard(.body(.large(.bold)))
                    .foregroundStyle(isSelected ? .sunsetOrange : .gray0)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(UIAsset.Colors.sunsetOrange.swiftUIColor)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 56)
            .background(rowBackground(isSelected: isSelected))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? UIAsset.Colors.sunsetOrange.swiftUIColor : .clear, lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func rowBackground(isSelected: Bool) -> Color {
        isSelected
            ? UIAsset.Colors.sunsetOrange.swiftUIColor.opacity(0.15)
            : UIAsset.Colors.surfaceChip.swiftUIColor
    }
}

#Preview {
    Color.black
        .sheet(isPresented: .constant(true)) {
            RegionSelectionSheet(
                regions: Region.fallbackRegions,
                appliedRegion: Region.fallbackRegions.first,
                onApply: { _ in },
                onCancel: {}
            )
        }
}
