import Foundation

struct OnboardingPage: Identifiable, Hashable, Sendable {
    enum AccentTheme: Sendable {
        case orange
        case darkOrange
        case blue
    }

    /// 일러스트 영역의 레이아웃 종류.
    /// - `topAlignedImage`: 단일 이미지를 상단(safe area 침범)에 부착. Step 0.
    /// - `bottomAlignedImage`: 단일 이미지를 하단 정렬 + 좌우 패딩 + 상단 토스트 슬롯. Step 1.
    /// - `taggedMap`: 분위기 태그와 지도 화면을 함께 노출. Step 3.
    enum Layout: Sendable, Hashable {
        case topAlignedImage
        case bottomAlignedImage
        case taggedMap
    }

    let id: Int
    let imageName: String
    let title: String
    let titleHighlight: String?
    let subtitle: String
    let theme: AccentTheme
    let gradient: OnboardingPageGradient
    let carouselImageNames: [String]
    let moodHeader: OnboardingMoodHeader?
    let layout: Layout
    let toastText: String?
}

struct OnboardingMoodHeader: Hashable, Sendable {
    /// 아래쪽 큰 칩 (선택된 표시).
    let primary: SpotTheme
    /// 위쪽 작은 칩 (비선택 표시).
    let secondary: SpotTheme
    /// 캡슐 하단 설명 문구. `\n`으로 줄바꿈.
    let description: String
}

extension OnboardingPage {
    static let defaultPages: [OnboardingPage] = [
        OnboardingPage(
            id: 0,
            imageName: "onboarding_0",
            title: "흩어진 포토스팟,\n이제 한 번에 찾을 수 있어요",
            titleHighlight: "한 번에 찾을 수 있어요",
            subtitle: "지도 뷰와 리스트 뷰를 통해\n원하는 방식으로 스팟을 쉽게 탐색해요.",
            theme: .orange,
            gradient: .orangeWarm,
            carouselImageNames: [],
            moodHeader: nil,
            layout: .topAlignedImage,
            toastText: nil
        ),
        OnboardingPage(
            id: 1,
            imageName: "onboarding_1",
            title: "나만의 스팟을\n기록하고 공유해보세요",
            titleHighlight: "나만의 스팟을",
            subtitle: "내가 촬영한 스팟을 지도에 남기고,\n기록한 스팟을 공개해보세요.",
            theme: .orange,
            gradient: .orangeWarm,
            carouselImageNames: [],
            moodHeader: nil,
            layout: .bottomAlignedImage,
            toastText: nil
        ),
        OnboardingPage(
            id: 2,
            imageName: "onboarding_1",
            title: "다른 사람의 스팟도\n만나볼 수 있어요",
            titleHighlight: "다른 사람의 스팟도",
            subtitle: "다른 유저가 발견한 스팟을 살펴보고,\n마음에 드는 스팟을 추천해보세요.",
            theme: .orange,
            gradient: .orangeWarm,
            carouselImageNames: [],
            moodHeader: nil,
            layout: .bottomAlignedImage,
            toastText: "이 스팟을 추천했어요."
        ),
        OnboardingPage(
            id: 3,
            imageName: "onboarding_0",
            title: "원하는 순간의 스팟을\n찾아보세요",
            titleHighlight: "원하는 순간의 스팟을",
            subtitle: "햇살부터 윤슬, 노을, 야경까지\n지금 찍고 싶은 분위기에 맞는 스팟을 찾아보세요.",
            theme: .orange,
            gradient: .orangeWarm,
            carouselImageNames: [],
            moodHeader: nil,
            layout: .taggedMap,
            toastText: nil
        )
    ]
}

extension OnboardingPageGradient {
    /// Step 0/1
    static let orangeWarm = OnboardingPageGradient(
        stops: [
            Stop(hex: 0xFA6133, location: 0),
            Stop(hex: 0xF69648, location: 1)
        ],
        startAnchor: .top,
        endAnchor: .bottom
    )

    /// Step 2 (노을)
    static let nightWarm = OnboardingPageGradient(
        stops: [
            Stop(hex: 0x131416, location: 0),
            Stop(hex: 0xFA6133, opacity: 0.5, location: 1),
        ],
        startAnchor: .top,
        endAnchor: .bottom
    )

    /// Step 3 (윤슬)
    static let nightCool = OnboardingPageGradient(
        stops: [
            Stop(hex: 0x131416, location: 0),
            Stop(hex: 0x1E8AF6, opacity: 0.5, location: 1),
        ],
        startAnchor: .top,
        endAnchor: .bottom
    )
}
