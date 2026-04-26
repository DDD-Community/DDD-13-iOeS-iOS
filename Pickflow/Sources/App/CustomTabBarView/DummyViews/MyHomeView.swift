import SwiftUI

struct MyHomeView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                HeroCard(
                    eyebrow: "MY",
                    title: "마이 탭",
                    description: "프로필 기능이 붙기 전에도 앱 흐름을 확인할 수 있게 정적 마이 화면을 우선 배치했습니다."
                )

                VStack(alignment: .leading, spacing: 12) {
                    profileSummary

                    infoTile(title: "내 활동", value: "12")
                    infoTile(title: "저장한 장소", value: "28")

                    infoTile(title: "내 활동", value: "12")
                    infoTile(title: "저장한 장소", value: "28")

                    infoTile(title: "내 활동", value: "12")
                    infoTile(title: "저장한 장소", value: "28")

                    infoTile(title: "내 활동", value: "12")
                    infoTile(title: "저장한 장소", value: "28")
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
        }
    }

    private var profileSummary: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(.gray10)
                .frame(width: 68, height: 68)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.gray70)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text("Pickflow User")
                    .pretendard(.heading(.small))
                    .foregroundStyle(.gray95)

                Text("profile@pickflow.app")
                    .pretendard(.body(.small()))
                    .foregroundStyle(.gray60)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.gray0)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.gray10, lineWidth: 1)
        )
    }

    private func infoTile(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .pretendard(.body(.medium()))
                .foregroundStyle(.gray70)

            Spacer()

            Text(value)
                .pretendard(.heading(.small))
                .foregroundStyle(.gray95)
        }
        .padding(18)
        .background(.gray0)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.gray10, lineWidth: 1)
        )
    }
}
