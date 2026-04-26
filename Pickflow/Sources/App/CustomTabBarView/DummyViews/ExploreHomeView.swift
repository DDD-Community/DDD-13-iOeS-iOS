import SwiftUI

struct ExploreHomeView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                HeroCard(
                    eyebrow: "EXPLORE",
                    title: "탐색 탭",
                    description: "지금 발견할 장소와 순간을 한 번에 훑을 수 있도록 시작 지점을 크게 잡았습니다."
                )

                VStack(alignment: .leading, spacing: 14) {
                    Text("빠른 탐색")
                        .pretendard(.heading(.small))
                        .foregroundStyle(.gray95)

                    HStack(spacing: 12) {
                        quickCard(title: "주변 스팟", caption: "가까운 추천")
                        quickCard(title: "인기 저장", caption: "많이 담은 장소")
                    }

                    HStack(spacing: 12) {
                        quickCard(title: "주변 스팟", caption: "가까운 추천")
                        quickCard(title: "인기 저장", caption: "많이 담은 장소")
                    }

                    HStack(spacing: 12) {
                        quickCard(title: "주변 스팟", caption: "가까운 추천")
                        quickCard(title: "인기 저장", caption: "많이 담은 장소")
                    }

                    HStack(spacing: 12) {
                        quickCard(title: "주변 스팟", caption: "가까운 추천")
                        quickCard(title: "인기 저장", caption: "많이 담은 장소")
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .onAppear {
                print("ExploreHomeView, VStack, onAppear")
            }
        }
        .onAppear {
            print("ExploreHomeView, ScrollView, onAppear")
        }
    }

    private func quickCard(title: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .pretendard(.body(.medium(.bold)))
                .foregroundStyle(.gray95)

            Text(caption)
                .pretendard(.body(.small()))
                .foregroundStyle(.gray60)
        }
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
        .padding(18)
        .background(.gray0)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.gray10, lineWidth: 1)
        )
    }
}
