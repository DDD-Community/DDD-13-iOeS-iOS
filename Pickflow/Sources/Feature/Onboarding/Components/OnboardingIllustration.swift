import SwiftUI

/// 페이지별 일러스트. 레이아웃은 `OnboardingPage.layout` switch로 분기.
/// - `.topAlignedImage` (Step 0): 단일 이미지 상단 정렬, safe area 침범.
/// - `.bottomAlignedImage` (Step 1): 단일 이미지 하단 정렬 + 좌우 패딩 + 상단 토스트 슬롯.
/// - `.taggedMap` (Step 3): 분위기 태그 + 지도 화면.
/// 상단 `PICKFLOW` 워드마크는 `OnboardingView`가 고정으로 렌더한다.
struct OnboardingIllustration: View {
    let page: OnboardingPage
    var isCarouselAnimating: Bool = true
    /// Step 1 이미지 상단에 띄울 토스트 텍스트. nil이면 비표시.
    var toastText: String? = nil

    var body: some View {
        ZStack {
            backgroundLayer
            content
        }
        .clipped()
    }

    @ViewBuilder
    private var content: some View {
        switch page.layout {
        case .topAlignedImage: topAlignedImage
        case .bottomAlignedImage: bottomAlignedImage
        case .taggedMap: taggedMap
        }
    }

    /// Step 0/1은 그라데이션 단독, Step 2/3은 panel base 위에 그라데이션 50% opacity.
    @ViewBuilder
    private var backgroundLayer: some View {
        switch page.layout {
        case .topAlignedImage, .bottomAlignedImage, .taggedMap:
            page.gradient.linearGradient
                .ignoresSafeArea()
        }
    }

    // MARK: - Layouts

    private var topAlignedImage: some View {
        VStack(spacing: 0) {
            phoneImage
                .padding(.horizontal, 60)
            Spacer(minLength: 0)
        }
        .ignoresSafeArea(edges: .top)
    }

    private var bottomAlignedImage: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 60)
            phoneImage
                .padding(.horizontal, 60)
                .frame(maxWidth: .infinity, alignment: .bottom)
                .background(alignment: .top) {
                    if let toastText = toastText ?? page.toastText {
                        OnboardingToast(text: toastText)
                            .offset(y: -90)
                            .transition(.offset(y: 180).combined(with: .opacity))
                    }
                }
        }
    }

    private var taggedMap: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 76)

            HStack(spacing: 8) {
                ForEach(SpotTheme.allCases, id: \.rawValue) { theme in
                    HStack(spacing: 4) {
                        Image(theme.iconAssetName)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .foregroundStyle(theme.accentColor)
                        Text(theme.displayName)
                            .pretendard(.body(.small()))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 10)
                    .frame(height: 32)
                    .background(
                        OnboardingPalette.panelBackground,
                        in: RoundedRectangle(cornerRadius: 6)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(
                                theme == .sunset ? OnboardingPalette.accentOrange : .clear,
                                lineWidth: 1
                            )
                    }
                }
            }

            phoneImage
                .padding(.horizontal, 52)
                .padding(.top, 12)
                .frame(maxWidth: .infinity, alignment: .bottom)
        }
    }

    private var phoneImage: some View {
        Image(page.imageName)
            .resizable()
            .scaledToFit()
            .shadow(color: .black.opacity(0.35), radius: 24, x: 0, y: 10)
    }
}

#Preview("Step 0") {
    OnboardingIllustration(page: OnboardingPage.defaultPages[0])
}

#Preview("Step 1 (with toast)") {
    OnboardingIllustration(
        page: OnboardingPage.defaultPages[1],
        toastText: "나만의 스팟이 등록되었어요!"
    )
}

#Preview("Step 2 (published spot)") {
    OnboardingIllustration(
        page: OnboardingPage.defaultPages[2],
        toastText: "이 스팟을 추천했어요."
    )
}

#Preview("Step 3 (tagged map)") {
    OnboardingIllustration(page: OnboardingPage.defaultPages[3])
}
