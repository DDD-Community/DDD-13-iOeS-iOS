import SwiftUI
import UIKit

/// UIHostingController subclass that prevents UIKit from shifting the view frame
/// when a UITextField (via UIViewRepresentable) becomes first responder.
/// Combines three layers of defense across iOS versions:
/// 1. safeAreaRegions = .container (iOS 16+) — excludes keyboard from safe area
/// 2. Direct keyboard notification observer — counteracts frame movement via matching animation
/// 3. Legacy @objc dynamic selector overrides — catches older UIHostingController internals
final class KeyboardFixedHostingController<Content: View>: UIHostingController<Content> {
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 16.0, *) {
            safeAreaRegions = .container
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func handleKeyboardWillShow(_ notification: Notification) {
        let userInfo = notification.userInfo
        // Guard: only reset frame when keyboard is actually appearing on screen.
        // keyboardWillChangeFrameNotification also fires during interactive dismiss,
        // which would fight against scrollDismissesKeyboard(.interactively).
        guard let endFrame = (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
              endFrame.minY < UIScreen.main.bounds.height else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let duration = (userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.25
            let curveValue = (userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue ?? 7
            UIView.animate(
                withDuration: duration,
                delay: 0,
                options: .init(rawValue: curveValue << 16)
            ) {
                self.view.frame.origin.y = 0
            }
        }
    }

    @objc dynamic func keyboardWillShowWithNotification(_ notification: Notification) {}
    @objc dynamic func keyboardWillHideWithNotification(_ notification: Notification) {}
    @objc dynamic func keyboardWillChangeFrameWithNotification(_ notification: Notification) {}
}

extension View {
    func fullScreenCoverKeyboardFixed<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        background {
            KeyboardFixedPresenterView(isPresented: isPresented, presentedContent: content)
        }
    }
}

private struct KeyboardFixedPresenterView<Content: View>: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let presentedContent: () -> Content

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        let coordinator = context.coordinator

        if isPresented {
            guard coordinator.hosted == nil, !coordinator.isAnimating else {
                coordinator.hosted?.rootView = presentedContent()
                return
            }
            coordinator.isAnimating = true
            let controller = KeyboardFixedHostingController(rootView: presentedContent())
            controller.modalPresentationStyle = .fullScreen
            uiViewController.present(controller, animated: true) {
                coordinator.isAnimating = false
            }
            coordinator.hosted = controller
        } else {
            guard coordinator.hosted != nil, !coordinator.isAnimating else { return }
            coordinator.isAnimating = true
            uiViewController.dismiss(animated: true) {
                coordinator.hosted = nil
                coordinator.isAnimating = false
            }
        }
    }

    final class Coordinator {
        var hosted: KeyboardFixedHostingController<Content>?
        var isAnimating = false
    }
}
