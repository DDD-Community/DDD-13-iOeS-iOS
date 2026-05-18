import UIKit

// 시트 medium → sheet large → full cover 3단 phase를 한 컨트롤러가 책임진다.
// SwiftUI 콘텐츠는 건드리지 않고 프레임/cornerRadius/dim/grab handle 알파만 보간한다.
@MainActor
final class SpotPresentationController: UIPresentationController {

    var phase: SpotPresentationPhase = .sheetMedium {
        didSet {
            guard oldValue != phase else { return }
            animateLayout()
            onPhaseChange?(phase)
        }
    }

    var onPhaseChange: ((SpotPresentationPhase) -> Void)?

    private(set) var isInteracting = false

    private let dimmingView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0)
        return v
    }()

    private let grabHandle: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.white.withAlphaComponent(0.35)
        v.layer.cornerRadius = 2.5
        return v
    }()

    override var frameOfPresentedViewInContainerView: CGRect {
        guard let container = containerView else { return .zero }
        switch phase {
        case .sheetMedium:
            let h = container.bounds.height * 0.55
            return CGRect(x: 0, y: container.bounds.height - h, width: container.bounds.width, height: h)
        case .sheetLarge:
            let h = container.bounds.height * 0.92
            return CGRect(x: 0, y: container.bounds.height - h, width: container.bounds.width, height: h)
        case .fullCover:
            return container.bounds
        }
    }

    override func presentationTransitionWillBegin() {
        guard let container = containerView, let presented = presentedView else { return }

        container.addSubview(dimmingView)
        dimmingView.frame = container.bounds
        dimmingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        presented.layer.cornerRadius = 20
        presented.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        presented.clipsToBounds = true

        // grab handle을 presented view 위에 오버레이.
        presented.addSubview(grabHandle)
        grabHandle.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            grabHandle.centerXAnchor.constraint(equalTo: presented.centerXAnchor),
            grabHandle.topAnchor.constraint(equalTo: presented.topAnchor, constant: 8),
            grabHandle.widthAnchor.constraint(equalToConstant: 40),
            grabHandle.heightAnchor.constraint(equalToConstant: 5),
        ])

        guard let coordinator = presentedViewController.transitionCoordinator else {
            dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
            return
        }
        coordinator.animate { [weak self] _ in
            self?.dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        }
    }

    override func dismissalTransitionWillBegin() {
        guard let coordinator = presentedViewController.transitionCoordinator else {
            dimmingView.backgroundColor = .clear
            return
        }
        coordinator.animate { [weak self] _ in
            self?.dimmingView.backgroundColor = .clear
        }
    }

    override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        guard !isInteracting else { return }
        presentedView?.frame = frameOfPresentedViewInContainerView
    }

    func beginInteractive() { isInteracting = true }

    // 손가락에 맞춰 frame/cornerRadius/grab handle을 실시간 보간.
    func applyInteractiveOffset(dy: CGFloat) {
        guard let container = containerView, let presented = presentedView else { return }
        let base = frameOfPresentedViewInContainerView
        let proposedY = max(0, base.origin.y + dy)
        let proposedH = container.bounds.height - proposedY
        presented.frame = CGRect(x: 0, y: proposedY, width: container.bounds.width, height: proposedH)

        // 풀스크린에 가까워질수록 cornerRadius=0, grab handle 알파=0.
        let fullProgress = 1 - min(1, max(0, proposedY / 40))
        presented.layer.cornerRadius = 20 * (1 - fullProgress)
        grabHandle.alpha = 1 - fullProgress
    }

    func settleToCurrentPhase() {
        isInteracting = false
        animateLayout()
    }

    private func animateLayout() {
        UIView.animate(
            withDuration: 0.35,
            delay: 0,
            usingSpringWithDamping: 0.86,
            initialSpringVelocity: 0,
            options: [.allowUserInteraction]
        ) { [weak self] in
            guard let self else { return }
            self.presentedView?.frame = self.frameOfPresentedViewInContainerView
            self.presentedView?.layer.cornerRadius = self.phase == .fullCover ? 0 : 20
            self.grabHandle.alpha = self.phase == .fullCover ? 0 : 1
        }
    }
}
