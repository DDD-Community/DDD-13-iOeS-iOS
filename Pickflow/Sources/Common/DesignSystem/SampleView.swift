import SwiftUI

struct SampleView: View {
    private let previewText = "일상 속 반짝임, 실패 없이 포착하세요"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                heroSection
                typographySection
                grayPaletteSection
            }
            .padding(24)
        }
        .background(
            LinearGradient(
                colors: [UIAsset.Colors.gray0.swiftUIColor, UIAsset.Colors.gray5.swiftUIColor],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Pickflow Design System")
                .pretendard(.label(.medium))
                .foregroundStyle(.gray60)

            Text("일상 속 반짝임,\n실패 없이 포착하세요")
                .pretendard(.display(.large))
                .foregroundStyle(.gray95)

            Text("Pretendard 타이포 스케일과 gray 팔레트를 한 화면에서 바로 검증할 수 있도록 구성했습니다.")
                .pretendard(.body(.medium()))
                .foregroundStyle(.gray60)

            HStack(spacing: 12) {
                tag("gray95 foreground", color: .gray95)
                tag("gray10 border", color: .gray10)
            }
        }
        .padding(24)
        .background(.gray0)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.gray10, lineWidth: 1)
        )
    }

    private var typographySection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Typography")
                .pretendard(.heading(.small))
                .foregroundStyle(.gray95)

            VStack(spacing: 0) {
                ForEach(PretendardStyle.allCases, id: \.self) { style in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(sampleName(for: style))
                            .pretendard(.label(.small))
                            .foregroundStyle(.gray50)

                        Text(previewText)
                            .pretendard(style)
                            .foregroundStyle(.gray90)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 14)

                    if style != PretendardStyle.allCases.last {
                        Divider()
                            .overlay(.gray10)
                    }
                }
            }
            .padding(.horizontal, 20)
            .background(.gray0)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.gray10, lineWidth: 1)
            )
        }
    }

    private var grayPaletteSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Gray Palette")
                .pretendard(.heading(.small))
                .foregroundStyle(.gray95)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 132), spacing: 12)], spacing: 12) {
                ForEach(UIAsset.Colors.allCases, id: \.self) { gray in
                    VStack(alignment: .leading, spacing: 12) {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(gray)
                            .frame(height: 84)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(.gray10, lineWidth: gray == .gray0 ? 1 : 0)
                            )

                        Text(gray.rawValue)
                            .pretendard(.label(.medium))
                            .foregroundStyle(.gray95)

                        Text("Color asset")
                            .pretendard(.body(.small()))
                            .foregroundStyle(.gray60)
                    }
                    .padding(14)
                    .background(.gray0)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(.gray10, lineWidth: 1)
                    )
                }
            }
        }
    }

    private func tag(_ title: String, color: UIAsset.Colors) -> some View {
        Text(title)
            .pretendard(.label(.small))
            .foregroundStyle(color == .gray10 ? .gray80 : .gray0)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(color)
            .clipShape(Capsule())
    }

    private func sampleName(for style: PretendardStyle) -> String {
        switch style {
        case let .display(size):
            "Display \(size.rawValue)"
        case let .heading(size):
            "Heading \(size.rawValue)"
        case let .body(size):
            size.weight == .bold ? "Body \(size.sizeName)-bold" : "Body \(size.sizeName)"
        case let .label(size):
            "Label \(size.rawValue)"
        }
    }
}

#Preview {
    SampleView()
}
