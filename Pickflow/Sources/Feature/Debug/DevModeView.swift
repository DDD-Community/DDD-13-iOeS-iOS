import SwiftUI

/// 개발·QA용 설정을 모아두는 화면. 탭바의 마이 탭 연타로 진입한다.
///
/// 기능이 늘어날 것을 전제로 섹션 단위로 구성했다. 새 항목은 `body` 에 섹션을 하나 더하면 된다.
struct DevModeView: View {
    @ObservedObject var controller: DevModeController
    private let tokenStore: TokenStoreProtocol
    let onClose: () -> Void

    @State private var selectedEnvironment: APIEnvironment = APIEnvironment.current
    @State private var isRestartNoticePresented = false

    init(
        controller: DevModeController,
        tokenStore: TokenStoreProtocol,
        onClose: @escaping () -> Void = {}
    ) {
        self.controller = controller
        self.tokenStore = tokenStore
        self.onClose = onClose
    }

    var body: some View {
        NavigationStack {
            ZStack {
                UIAsset.Colors.gray95.color.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        apiEnvironmentSection
                        displaySection
                        appInfoSection
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Dev Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기", action: onClose)
                        .foregroundStyle(.gray10)
                }
            }
            .alert("앱을 다시 실행해 주세요", isPresented: $isRestartNoticePresented) {
                Button("확인", role: .cancel) {}
            } message: {
                Text("서버가 바뀌어 로그아웃했어요. 앱을 완전히 종료했다가 다시 열면 \(selectedEnvironment.displayName) 으로 연결돼요.")
            }
        }
    }

    // MARK: - API 환경

    private var apiEnvironmentSection: some View {
        section("API 환경") {
            Text("이 빌드의 기본값은 \(APIEnvironment.buildDefault.displayName) 이에요.\n앱을 업데이트하면 기본값으로 돌아가요.")
                .pretendard(.body(.small()))
                .foregroundStyle(.gray30)

            if let forced = APIEnvironment.launchArgumentOverride {
                // 실행 인자가 우선하므로 아래에서 무엇을 고르든 반영되지 않는다.
                Text("실행 인자로 \(forced.displayName) 이 고정돼 있어요.\n스킴에서 -apiEnvironment 를 빼야 아래 선택이 적용돼요.")
                    .pretendard(.body(.small()))
                    .foregroundStyle(.sunsetOrange)
            }

            VStack(spacing: 8) {
                ForEach(APIEnvironment.allCases, id: \.self) { environment in
                    environmentRow(environment)
                }
            }

            labeledValue("현재 요청 주소", APIEnvironment.current.baseURL, highlighted: true)
        }
    }

    private func environmentRow(_ environment: APIEnvironment) -> some View {
        let isSelected = selectedEnvironment == environment
        return Button {
            guard !isSelected else { return }
            apply(environment)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(environment.displayName)
                            .pretendard(.body(.medium(.bold)))
                            .foregroundStyle(.gray0)

                        if environment == APIEnvironment.buildDefault {
                            Text("기본")
                                .pretendard(.body(.small()))
                                .foregroundStyle(.gray30)
                        }
                    }

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
        if environment == APIEnvironment.buildDefault {
            APIEnvironment.clearOverride()
        } else {
            APIEnvironment.setOverride(environment)
        }
        // 토큰은 반대편 서버에서 발급된 값이라 그대로 쓰면 401 이 난다.
        try? tokenStore.clear()
        selectedEnvironment = environment
        isRestartNoticePresented = true
    }

    // MARK: - 표시

    private var displaySection: some View {
        section("표시") {
            Toggle(isOn: $controller.isBadgePreferred) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("환경 배지 띄우기")
                        .pretendard(.body(.medium(.bold)))
                        .foregroundStyle(.gray0)
                    Text("화면 위에 현재 환경을 항상 표시해요.")
                        .pretendard(.body(.small()))
                        .foregroundStyle(.gray30)
                }
            }
            .tint(Color(.sunsetOrange))
            .padding(16)
            .background(UIAsset.Colors.gray90.swiftUIColor, in: RoundedRectangle(cornerRadius: 8))

            if APIEnvironment.isOverridden {
                Text("기본 환경이 아닐 때는 꺼두어도 배지가 표시돼요.")
                    .pretendard(.body(.small()))
                    .foregroundStyle(.gray30)
            }
        }
    }

    // MARK: - 앱 정보

    private var appInfoSection: some View {
        section("앱 정보") {
            labeledValue("버전", APIEnvironment.currentAppVersion)
            labeledValue("빌드", Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-")
            labeledValue("번들 ID", Bundle.main.bundleIdentifier ?? "-")
        }
    }

    // MARK: - Building blocks

    @ViewBuilder
    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .pretendard(.heading(.small))
                .foregroundStyle(.gray0)
            content()
        }
    }

    private func labeledValue(_ label: String, _ value: String, highlighted: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .pretendard(.body(.small(.bold)))
                .foregroundStyle(.gray30)
            Text(value)
                .pretendard(.body(.small()))
                .foregroundStyle(highlighted ? .sunsetOrange : .gray10)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
