import SwiftUI

struct SavedHomeView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                NavigationLink("2 depth로 이동", value: DummyRoute.detail(from: "저장"))
                    .pretendard(.label(.medium))
                    .foregroundStyle(.gray0)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(.gray90)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                HeroCard(
                    eyebrow: "SAVED",
                    title: "저장 탭",
                    description: "모아둔 장소와 후보를 정리해두는 보관함 성격의 레이아웃으로 구성했습니다."
                )

                VStack(spacing: 12) {
                    savedRow(title: "다음 주말 후보", subtitle: "3개의 장소")
                    savedRow(title: "야경 리스트", subtitle: "최근 저장됨")
                    savedRow(title: "카페 모음", subtitle: "정리 필요")
                    savedRow(title: "다음 주말 후보", subtitle: "3개의 장소")
                    savedRow(title: "야경 리스트", subtitle: "최근 저장됨")
                    savedRow(title: "카페 모음", subtitle: "정리 필요")
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
        }
    }

    private func savedRow(title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.gray10)
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.gray70)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .pretendard(.body(.medium(.bold)))
                    .foregroundStyle(.gray95)

                Text(subtitle)
                    .pretendard(.body(.small()))
                    .foregroundStyle(.gray60)
            }

            Spacer()
        }
        .padding(16)
        .background(.gray0)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.gray10, lineWidth: 1)
        )
    }
}
