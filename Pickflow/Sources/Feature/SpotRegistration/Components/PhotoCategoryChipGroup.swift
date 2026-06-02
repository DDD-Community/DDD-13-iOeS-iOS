import SwiftUI

struct SpotThemeChipGroup: View {
    @Binding var selectedCategory: SpotTheme?

    var body: some View {
        LabeledSection(title: "사진 카테고리") {
            HStack(spacing: 12) {
                ForEach(SpotTheme.allCases, id: \.self) { category in
                    Button {
                        selectedCategory = selectedCategory == category ? nil : category
                    } label: {
                        HStack(spacing: 6) {
                            AssetImage(named: category.iconAssetName, size: 20) {
                                Text(category.iconEmoji)
                                    .font(.system(size: 20))
                            }
                            Text(category.displayName)
                                .pretendard(.body(.medium(.bold)))
                                .foregroundStyle(selectedCategory == category ? .white : Color.spotSecondaryText)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.spotInputBackground, in: RoundedRectangle(cornerRadius: 8))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    selectedCategory == category ? Color.spotOrange : Color.spotChipBorder,
                                    lineWidth: selectedCategory == category ? 1.5 : 1
                                )
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("사진 카테고리 \(category.displayName)")
                }

                Spacer(minLength: 0)
            }
        }
    }
}
