import SwiftUI

/// 온보딩 화면 공용 토스트(체크 아이콘 + 텍스트, gray0 배경).
struct OnboardingToast: View {
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(.gray95)
            Text(text)
                .pretendard(.body(.medium(.bold)))
                .foregroundStyle(.gray95)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.gray0)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 4)
    }
}

#Preview {
    OnboardingToast(text: "나만의 스팟이 등록되었어요!")
        .padding()
        .background(Color.orange)
}
