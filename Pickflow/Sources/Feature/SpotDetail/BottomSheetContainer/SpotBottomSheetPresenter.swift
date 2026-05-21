import SwiftUI
import UIKit

// SwiftUI에서 UIKit 커스텀 시트(medium ↔ large ↔ fullCover)를 띄우는 modifier.
// 사용:
//   .spotBottomSheet(isPresented: $flag, viewModel: vm) {
//       SpotShellRootView(viewModel: vm)
//   }
// viewModel을 주입하면 UIKit이 결정한 phase가 VM에 단방향 전파된다.
extension View {
    func spotBottomSheet<SheetContent: View>(
        isPresented: Binding<Bool>,
        viewModel: SpotDetailViewModel? = nil,
        @ViewBuilder content: @escaping () -> SheetContent
    ) -> some View {
        background(
            SpotBottomSheetPresenter(
                isPresented: isPresented,
                viewModel: viewModel,
                sheetContent: content
            )
        )
    }
}

private struct SpotBottomSheetPresenter<SheetContent: View>: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let viewModel: SpotDetailViewModel?
    let sheetContent: () -> SheetContent

    func makeUIViewController(context: Context) -> UIViewController { UIViewController() }

    func updateUIViewController(_ host: UIViewController, context: Context) {
        context.coordinator.sync(
            host: host,
            isPresented: isPresented,
            viewModel: viewModel,
            sheetContent: sheetContent(),
            dismissBinding: $isPresented
        )
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    @MainActor
    final class Coordinator: NSObject {
        private weak var shell: SpotBottomSheetShellViewController<SheetContent>?
        private let delegate = SpotTransitioningDelegate()
        private var dismissBinding: Binding<Bool>?

        func sync(
            host: UIViewController,
            isPresented: Bool,
            viewModel: SpotDetailViewModel?,
            sheetContent: SheetContent,
            dismissBinding: Binding<Bool>
        ) {
            self.dismissBinding = dismissBinding

            if isPresented, shell == nil {
                let vc = SpotBottomSheetShellViewController(rootView: sheetContent)
                vc.modalPresentationStyle = .custom
                vc.transitioningDelegate = delegate

                vc.panCoordinator.onBegan = { [weak vc] in
                    vc?.spotPresentationController?.beginInteractive()
                }
                vc.panCoordinator.onTranslation = { [weak vc, weak viewModel] dy in
                    guard let pc = vc?.spotPresentationController else { return }
                    pc.applyInteractiveOffset(dy: dy)
                    // 라이브 phase: 손가락 위치가 임계선을 넘는 순간 chrome도 즉시 스왑.
                    // settle 시점의 cross-fade는 ShellRootView .animation modifier가 처리.
                    guard let vm = viewModel else { return }
                    switch pc.currentPhaseFromFrame() {
                    case .sheetMedium: vm.updateDetent(.medium)
                    case .sheetLarge:  vm.updateDetent(.large)
                    case .fullCover:   vm.promoteToFullCover()
                    }
                }
                vc.panCoordinator.onEnded = { [weak vc, weak self] dy, velocity in
                    guard let pc = vc?.spotPresentationController else { return }
                    let projected = dy + velocity * 0.15
                    let strongUp = projected < -160
                    let lightUp  = projected < -50
                    let strongDown = projected > 160
                    let lightDown  = projected > 50

                    switch pc.phase {
                    case .sheetMedium:
                        if strongUp { pc.phase = .fullCover }
                        else if lightUp { pc.phase = .sheetLarge }
                        else if dy > 140 || velocity > 1400 {
                            vc?.dismiss(animated: true) {
                                self?.shell = nil
                                self?.dismissBinding?.wrappedValue = false
                            }
                        }
                    case .sheetLarge:
                        if lightUp { pc.phase = .fullCover }
                        else if strongDown || lightDown { pc.phase = .sheetMedium }
                    case .fullCover:
                        if strongDown { pc.phase = .sheetMedium }
                        else if lightDown { pc.phase = .sheetLarge }
                    }
                    pc.settleToCurrentPhase()
                }

                shell = vc
                host.present(vc, animated: true) { [weak self, weak viewModel] in
                    let pc = self?.delegate.presentationController
                    vc.spotPresentationController = pc
                    pc?.onPhaseChange = { newPhase in
                        guard let vm = viewModel else { return }
                        switch newPhase {
                        case .sheetMedium: vm.updateDetent(.medium)
                        case .sheetLarge:  vm.updateDetent(.large)
                        case .fullCover:   vm.promoteToFullCover()
                        }
                    }
                }
            } else if !isPresented, let s = shell {
                s.dismiss(animated: true) { [weak self] in
                    self?.shell = nil
                }
            }
        }
    }
}
