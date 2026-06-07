import SwiftUI

struct SpotShellRootView: View {
    @ObservedObject var viewModel: SpotDetailViewModel
    var onDismiss: () -> Void = {}
    @State private var isLoginViewPresented = false
    @State private var pendingLogin = false
    // 미디엄 시트는 화면 하단 일부만 차지하므로 풀스크린 커버(clear 배경)로 띄워 화면 중앙에 배치한다.
    // 단, 커버 기본 슬라이드업 대신 fade in/out 으로 보이도록 커버 자체 애니메이션은 끄고
    // 내부 콘텐츠 opacity 로 페이드를 직접 제어한다.
    @State private var showLoginCover = false
    @State private var loginContentVisible = false

    private func presentLoginCover() {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { showLoginCover = true }
    }

    private func dismissLoginCover() {
        guard showLoginCover else { return }
        withAnimation(.easeInOut(duration: 0.2)) { loginContentVisible = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) { showLoginCover = false }
        }
    }

    var body: some View {
        Group {
            switch viewModel.presentationPhase {
            case .sheetMedium:
                SheetChromeView {
                    sheetMediumContent
                }
                .transition(.opacity)
            case .sheetLarge, .fullCover:
                SpotDetailView(viewModel: viewModel, onShellDismiss: onDismiss)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.presentationPhase)
        // 미디엄 시트에서는 SpotDetailView 의 로그인 유도 오버레이가 없으므로
        // 여기서 직접 띄운다. (large/fullCover 는 SpotDetailView 가 처리해 중복 방지)
        // isLoginRequired 변화를 fade 커버로 매핑 (커버 전환 애니메이션은 끄고 콘텐츠만 페이드).
        .onChange(of: viewModel.isLoginRequired) { _, required in
            if required, viewModel.presentationPhase == .sheetMedium {
                presentLoginCover()
            } else if !required {
                dismissLoginCover()
            }
        }
        .fullScreenCover(isPresented: $showLoginCover, onDismiss: {
            loginContentVisible = false
            // 팝업 dismiss 가 끝난 뒤 로그인 화면을 띄워 커버 중첩 충돌을 피한다.
            if pendingLogin {
                pendingLogin = false
                isLoginViewPresented = true
            }
        }) {
            ZStack {
                Color.black.opacity(0.5).ignoresSafeArea()
                    .onTapGesture { viewModel.isLoginRequired = false }
                LoginPromptPopup(
                    onCancel: { viewModel.isLoginRequired = false },
                    onLogin: {
                        pendingLogin = true
                        viewModel.isLoginRequired = false
                    }
                )
                .padding(.horizontal, 32)
            }
            .opacity(loginContentVisible ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.2)) { loginContentVisible = true }
            }
            .presentationBackground(.clear)
        }
        .fullScreenCover(isPresented: $isLoginViewPresented) {
            LoginView(
                viewModel: LoginViewModel(socialLoginService: getSocialLoginService()),
                onSignInSucceeded: { isLoginViewPresented = false },
                isClosable: true
            )
        }
        .task {
            if viewModel.previewState == .idle {
                await viewModel.onAppear()
            }
        }
        .onAppear {
            if viewModel.previewState == .idle {
                Task { await viewModel.onAppear() }
            }
        }
    }

    @ViewBuilder
    private var sheetMediumContent: some View {
        switch viewModel.previewState {
        case .idle, .loading:
            loadingPlaceholder
        case let .failed(message):
            errorPlaceholder(message: message)
        case let .loaded(preview):
            SpotDetailSheetContentView(
                preview: preview,
                isBookmarked: viewModel.isBookmarked,
                onClose: onDismiss,
                onRoute: viewModel.openNaverMapsRoute,
                onBookmark: { Task { await viewModel.toggleBookmark() } }
            )
        }
    }

    private var loadingPlaceholder: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(UIAsset.Colors.gray0.swiftUIColor)
            Text("정보를 불러오는 중…")
                .pretendard(.body(.medium(.regular)))
                .foregroundStyle(.gray30)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .padding(.horizontal, 20)
    }

    private func errorPlaceholder(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundStyle(.gray30)
            Text("정보를 불러오지 못했어요")
                .pretendard(.body(.large(.bold)))
                .foregroundStyle(.gray5)
            Text(message)
                .pretendard(.body(.small(.regular)))
                .foregroundStyle(.gray30)
                .multilineTextAlignment(.center)
            Button("다시 시도") {
                Task { await viewModel.onAppear() }
            }
            .pretendard(.body(.medium(.bold)))
            .foregroundStyle(.sunsetOrange)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
    }
}

#if DEBUG
#Preview("Medium Sheet") {
    @Previewable @StateObject var viewModel = SpotDetailDebugFactory.makeViewModel(spotId: 1)

    ZStack(alignment: .bottom) {
        Color.black.opacity(0.4).ignoresSafeArea()
        SpotShellRootView(viewModel: viewModel)
            .frame(maxHeight: UIScreen.main.bounds.height * 0.55)
    }
    .preferredColorScheme(.dark)
}

#Preview("Medium Sheet — 주소 펼침/저장됨") {
    ZStack(alignment: .bottom) {
        Color.black.opacity(0.4).ignoresSafeArea()
        SheetChromeView {
            SpotDetailSheetContentView(
                preview: SpotDetailDebugFixture.preview,
                isBookmarked: true,
                initialAddressExpanded: true
            )
        }
        .frame(maxHeight: UIScreen.main.bounds.height * 0.55)
    }
    .preferredColorScheme(.dark)
}
#endif
