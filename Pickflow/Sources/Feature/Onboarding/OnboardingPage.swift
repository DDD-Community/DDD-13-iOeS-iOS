import Foundation

struct OnboardingPage: Identifiable, Hashable, Sendable {
    enum AccentTheme: Sendable {
        case orange
      case darkOrange
        case blue
    }

    let id: Int
    let imageName: String
    let title: String
    let titleHighlight: String?
    let subtitle: String
    let theme: AccentTheme
}

extension OnboardingPage {
    static let defaultPages: [OnboardingPage] = [
        OnboardingPage(
            id: 0,
            imageName: "onboarding_0",
            title: "흩어진 포토스팟,\n이제 한 번에 찾을 수 있어요",
            titleHighlight: "한 번에 찾을 수 있어요",
            subtitle: "지도 뷰와 리스트 뷰를 통해\n원하는 방식으로 스팟을 쉽게 탐색해요.",
            theme: .orange
        ),
        OnboardingPage(
            id: 1,
            imageName: "onboarding_1",
            title: "나만의 스팟을\n기록하고 공유해보세요",
            titleHighlight: "나만의 스팟을",
            subtitle: "내가 촬영한 스팟을 지도에 남기고\n확인할 수 있어요.",
            theme: .orange
        ),
        OnboardingPage(
            id: 2,
            imageName: "onboarding_2",
            title: "하루의 끝자락에서,\n노을이 가장 아름다운 순간",
            titleHighlight: "노을이 가장 아름다운 순간",
            subtitle: "노을 태그로,\n그 순간을 담은 스팟을 찾아보세요.",
            theme: .orange
        ),
        OnboardingPage(
            id: 3,
            imageName: "onboarding_3",
            title: "물가에 빛이 닿을 때,\n윤슬이 가장 반짝이는 순간",
            titleHighlight: "윤슬이 가장 반짝이는 순간",
            subtitle: "윤슬 태그로,\n그 순간을 담은 스팟을 찾아보세요.",
            theme: .blue
        )
    ]
}
