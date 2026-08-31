import SwiftUI

/// 지역(대전/서울) 선택 바텀시트. [적용하기]를 눌러야만 확정되고, 취소/바깥 탭 dismiss는
/// pending 선택을 폐기한다(§2.2 바텀시트 동작 원칙).
///
/// 네이티브 `.sheet`(`presentationSizing(.page)` 포함)가 이 iOS 버전에서 커스텀
/// `presentationDetents(.height)` + `presentationCornerRadius` 조합에서 좌우에 8pt 여백을 두고
/// 카드처럼 뜨는 현상이 있어(fit 안 됨 확인됨), 네이티브 시트 대신 이 화면에 이미 있는 다른
/// 팝업들(`LoginPromptPopup` 등)과 같은 방식의 커스텀 오버레이로 구현한다 — `RegionSelectionOverlay` 참고.
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
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.white.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 16)

            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("어느 지역을 둘러볼까요?")
                        .pretendard(.heading(.small))
                        .foregroundStyle(.gray0)
                    Text("선택한 지역을 기준으로 스팟을 보여드려요.")
                        .pretendard(.body(.medium()))
                        .foregroundStyle(.gray50)
                }

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
            // 홈 인디케이터(하단 안전영역) 회피 — 이 화면은 배경이 화면 맨 아래까지 이어져야 해서
            // ignoresSafeArea를 쓰는 대신 고정값으로 여유를 둔다.
            .padding(.bottom, 20 + 34)
        }
        .frame(maxWidth: .infinity)
        .background(UIAsset.Colors.surfaceModal.swiftUIColor)
        .clipShape(.rect(topLeadingRadius: 20, topTrailingRadius: 20))
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

/// `RegionSelectionSheet`를 화면 하단에 붙여 스크림과 함께 띄우는 오버레이.
/// 바깥(스크림) 탭 시 취소와 동일하게 처리한다.
struct RegionSelectionOverlay: View {
    let regions: [Region]
    let appliedRegion: Region?
    let onApply: (Region) -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture(perform: onCancel)
                // 딤 배경은 시트와 별개로 페이드로만 등장/퇴장해야 한다. 부모(ZStack) 전체에
                // .move 트랜지션을 걸면 이 배경까지 아래→위로 슬라이드돼 보이므로 여기서 개별 지정.
                .transition(.opacity)

            RegionSelectionSheet(
                regions: regions,
                appliedRegion: appliedRegion,
                onApply: onApply,
                onCancel: onCancel
            )
            .transition(.move(edge: .bottom))
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

#Preview {
    Color.black
        .overlay {
            RegionSelectionOverlay(
                regions: Region.fallbackRegions,
                appliedRegion: Region.fallbackRegions.first,
                onApply: { _ in },
                onCancel: {}
            )
        }
}
