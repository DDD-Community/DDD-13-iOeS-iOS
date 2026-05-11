import SwiftUI

struct OnboardingIllustration: View {
    let page: OnboardingPage

    var body: some View {
        ZStack(alignment: .topLeading) {
      LinearGradient(
        stops: page.theme.gradientColos,
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()
          
          VStack(alignment: .center) {
            Image(page.imageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, alignment: .bottom)
                
          }
          .ignoresSafeArea()

            Text("PICKFLOW")
            .font(.custom("Rambla-Bold", size: 28))
            .tracking(-0.056)
            .lineSpacing(1.11)
                .foregroundStyle(OnboardingPalette.title)
                .padding(.leading, 20)
                .padding(.top, 16)
        }
    }
}

#Preview {
  let pages = OnboardingPage.defaultPages
  let index = 3
  OnboardingPageView(page: pages[index], currentIndex: index, pageCount: pages.count) {
    
  }
}
