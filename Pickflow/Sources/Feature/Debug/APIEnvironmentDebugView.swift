#if DEBUG
import SwiftUI

/// Debug 빌드 전용 API 서버 전환 화면.
///
/// 서버를 바꾸면 기존 토큰은 반대편 서버에서 발급된 값이라 그대로 쓰면 401 이 난다.
/// 그래서 전환 시 토큰을 비우고, 진행 중인 세션/캐시가 섞이지 않도록 앱 재시작을 안내한다.
struct APIEnvironmentDebugView: View {
    private let tokenStore: TokenStoreProtocol

    @State private var selection: APIEnvironment = APIEnvironment.current
    @State private var isRestartNoticePresented = false

    init(tokenStore: TokenStoreProtocol) {
        self.tokenStore = tokenStore
    }

    var body: some View {
        ZStack {
            UIAsset.Colors.gray95.color.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("API 환경")
                        .pretendard(.heading(.large))
                        .foregroundStyle(.gray0)

                    Text("빌드 기본값은 \(APIEnvironment.buildDefault.displayName) 이에요.\nDebug 빌드에서만 바꿀 수 있고, 운영 빌드에는 이 화면이 없어요.")
                        .pretendard(.body(.small()))
                        .foregroundStyle(.gray30)
                }

                VStack(spacing: 8) {
                    ForEach(APIEnvironment.allCases, id: \.self) { environment in
                        environmentRow(environment)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("현재 요청 주소")
                        .pretendard(.body(.small(.bold)))
                        .foregroundStyle(.gray30)

                    Text(APIEnvironment.current.baseURL)
                        .pretendard(.body(.small()))
                        .foregroundStyle(.sunsetOrange)
                        .textSelection(.enabled)
                }

                Spacer()
            }
            .padding(20)
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("앱을 다시 실행해 주세요", isPresented: $isRestartNoticePresented) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("서버가 바뀌어 로그아웃했어요. 앱을 완전히 종료했다가 다시 열면 \(selection.displayName) 으로 연결돼요.")
        }
    }

    private func environmentRow(_ environment: APIEnvironment) -> some View {
        let isSelected = selection == environment
        return Button {
            guard !isSelected else { return }
            apply(environment)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(environment.displayName)
                        .pretendard(.body(.medium(.bold)))
                        .foregroundStyle(.gray0)

                    Text(environment.baseURL)
                        .pretendard(.body(.small()))
                        .foregroundStyle(.gray30)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.sunsetOrange)
                }
            }
            .padding(16)
            .background(UIAsset.Colors.gray90.swiftUIColor, in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color(.sunsetOrange) : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func apply(_ environment: APIEnvironment) {
        APIEnvironment.setOverride(environment)
        try? tokenStore.clear()
        selection = environment
        isRestartNoticePresented = true
    }
}
#endif
