import SwiftUI

/// 탐색 상단 카테고리 필터. 선택은 다중이며, 비어 있으면 전체를 뜻한다.
///
/// 디자인 실측 기준 칩 하나가 84×40(아이콘 20 + 간격 6 + 좌우 패딩 14)이라
/// 4개 기준 폭이 360이다. 390pt 화면에서 좌우 여백 16을 빼면 358이라 2pt 모자라서,
/// 칩 치수를 임의로 줄이는 대신 가로 스크롤로 감쌌다.
/// 카테고리가 더 늘어나도 이 구조 그대로 버틴다.
struct SpotThemeFilterBar: View {
    @Binding var selectedThemes: Set<SpotTheme>
    var showsNewIndicators: Bool = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SpotTheme.allCases, id: \.self) { theme in
                    chip(theme)
                }
            }
        }
    }

    private func chip(_ theme: SpotTheme) -> some View {
        let isSelected = selectedThemes.contains(theme)
        return Button {
            if isSelected {
                selectedThemes.remove(theme)
            } else {
                selectedThemes.insert(theme)
            }
        } label: {
            ZStack(alignment: .topTrailing) {
                HStack(spacing: 6) {
                    AssetImage(named: theme.iconAssetName, size: 20) {
                        Text(theme.iconEmoji)
                            .font(.system(size: 16))
                    }

                    Text(theme.displayName)
                        .pretendard(.body(.large(.bold)))
                        .padding(.vertical, 8)
                        .foregroundStyle(isSelected ? .white : .primary)
                }
                .padding(.horizontal, 14)
                .background(.gray95)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                // 선택 stroke 는 카테고리와 무관하게 단일 주황(#FA6133) — 디자인 확인 완료.
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color(.sunsetOrange) : .clear, lineWidth: 1)
                )

                if showsNewIndicator(for: theme) {
                    Circle()
                        .fill(UIAsset.Colors.sunsetOrange.swiftUIColor)
                        .frame(width: 5, height: 5)
                        .padding(.top, 6)
                        .padding(.trailing, 6)
                }
            }
        }
        .accessibilityLabel("카테고리 \(theme.displayName)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func showsNewIndicator(for theme: SpotTheme) -> Bool {
        showsNewIndicators && (theme == .sunlight || theme == .nightView)
    }
}
