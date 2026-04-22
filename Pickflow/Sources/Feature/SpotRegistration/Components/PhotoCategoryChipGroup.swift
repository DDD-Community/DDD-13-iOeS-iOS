import SwiftUI

struct PhotoCategoryChipGroup: View {
    @Binding var selectedCategory: PhotoCategory?

    var body: some View {
        LabeledSection(title: "사진 카테고리") {
            HStack(spacing: 12) {
                ForEach(PhotoCategory.allCases, id: \.self) { category in
                    Button {
                        selectedCategory = selectedCategory == category ? nil : category
                    } label: {
                        HStack(spacing: 6) {
                            Text(category.iconEmoji)
                            Text(category.displayName)
                                .pretendard(.body(.medium(.bold)))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .frame(height: 44)
                        .background(Color.spotCardBackground, in: Capsule())
                        .overlay {
                            Capsule()
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
