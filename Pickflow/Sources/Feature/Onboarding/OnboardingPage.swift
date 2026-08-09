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
    /// - `moodCarousel`: mood 헤더(칩+설명) + focused center-mode 캐러셀. Step 2/3.
    enum Layout: Sendable, Hashable {
        case topAlignedImage
        case bottomAlignedImage
        case moodCarousel
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
            layout: .topAlignedImage
        ),
        OnboardingPage(
            id: 1,
            imageName: "onboarding_1",
            title: "나만의 스팟을\n기록하고 공유해보세요",
            titleHighlight: "나만의 스팟을",
            subtitle: "내가 촬영한 스팟을 지도에 남기고\n확인할 수 있어요.",
            theme: .orange,
            gradient: .orangeWarm,
            carouselImageNames: [],
            moodHeader: nil,
            layout: .bottomAlignedImage
        ),
        OnboardingPage(
            id: 2,
            imageName: "onboarding_2",
            title: "하루의 끝자락에서,\n노을이 가장 아름다운 순간",
            titleHighlight: "노을이 가장 아름다운 순간",
            subtitle: "노을 태그로,\n그 순간을 담은 스팟을 찾아보세요.",
            theme: .orange,
            gradient: .nightWarm,
            carouselImageNames: ["onboarding_2_pic_0", "onboarding_2_pic_1", "onboarding_2_pic_2"],
            moodHeader: OnboardingMoodHeader(
                primary: .sunset,
                secondary: .reflection,
                description: "해가 뜨거나 지려고 할 때에\n하늘이 햇빛을 받아 붉게 보이는 현상"
            ),
            layout: .moodCarousel
        ),
        OnboardingPage(
            id: 3,
            imageName: "onboarding_3",
            title: "물가에 빛이 닿을 때,\n윤슬이 가장 반짝이는 순간",
            titleHighlight: "윤슬이 가장 반짝이는 순간",
            subtitle: "윤슬 태그로,\n그 순간을 담은 스팟을 찾아보세요.",
            theme: .blue,
            gradient: .nightCool,
            carouselImageNames: ["onboarding_3_pic_0", "onboarding_3_pic_1", "onboarding_3_pic_2"],
            moodHeader: OnboardingMoodHeader(
                primary: .reflection,
                secondary: .sunset,
                description: "달빛이나 햇빛에 비치어 반짝이는 잔물결\n"
            ),
            layout: .moodCarousel
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
