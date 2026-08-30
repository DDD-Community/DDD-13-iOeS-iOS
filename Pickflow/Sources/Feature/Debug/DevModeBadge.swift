import SwiftUI

/// 현재 API 환경을 항상 보이게 띄우는 플로팅 배지.
///
/// 어느 서버에 붙어 있는지 모른 채 QA 하다 "데이터가 왜 이래" 로 시간을 쓰는 일을 막는다.
/// 눌러서 Dev Mode 화면으로 바로 들어갈 수 있다.
struct DevModeBadge: View {
    let environment: APIEnvironment
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Circle()
                    .fill(indicatorColor)
                    .frame(width: 8, height: 8)

                Text(environment.rawValue.uppercased())
                    .pretendard(.label(.medium))
                    .foregroundStyle(.gray0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.black.opacity(0.75), in: Capsule())
            .overlay(Capsule().stroke(indicatorColor.opacity(0.6), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("현재 API 환경 \(environment.displayName). 눌러서 Dev Mode 열기")
    }

    /// 운영은 초록, 그 외(개발)는 주황 — 잘못된 환경에 붙어 있으면 눈에 띄게.
    private var indicatorColor: Color {
        switch environment {
        case .prod: .green
        case .dev: Color(.sunsetOrange)
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        DevModeBadge(environment: .dev) {}
        DevModeBadge(environment: .prod) {}
    }
    .padding()
    .background(Color.black)
}
