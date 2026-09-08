import SwiftUI
import UIKit

/// 앱 콘텐츠 위에 강제 업데이트 게이트를 씌우는 래퍼.
///
/// 앱 시작 시 버전 정책을 확인하고, 강제 업데이트가 필요하면 `ForceUpdateView`를 전체 화면으로 덮어
/// 앱 사용을 막는다. 확인 중이거나 업데이트가 필요 없으면 `content`를 그대로 노출한다(앱 진입을 막지 않음).
struct ForceUpdateGate<Content: View>: View {
    @StateObject private var viewModel: ForceUpdateViewModel
    private let content: Content
    private let onLaunchChecksCompleted: () async -> Void

    init(
        viewModel: @autoclosure @escaping () -> ForceUpdateViewModel,
        onLaunchChecksCompleted: @escaping () async -> Void = {},
        @ViewBuilder content: () -> Content
    ) {
        _viewModel = StateObject(wrappedValue: viewModel())
        self.onLaunchChecksCompleted = onLaunchChecksCompleted
        self.content = content()
    }

    var body: some View {
        content
            .task {
                await viewModel.checkForUpdate()
                // 앱 버전(config) 정책 확인 응답 직후 바로 시작 — 지역 선택 스토어의 활성지역 선점 로드 등.
                await onLaunchChecksCompleted()
            }
            .fullScreenCover(isPresented: .constant(viewModel.isForceUpdateRequired)) {
                if let storeURL = viewModel.forceUpdateStoreURL {
                    ForceUpdateView(storeURL: storeURL) { url in
                        UIApplication.shared.open(url)
                    }
                }
            }
    }
}
