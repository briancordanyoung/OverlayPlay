import UIKit
import OverlayKit

internal class ViewController: UIViewController {
    internal var overlayViewController: OverlayViewController<ExampleView>?

    internal override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .gray
        delay(bySeconds: 1) { [weak self] in
            self?.activateOverlay()
        }

        // The following layout call have no effect.
        // delay(bySeconds: 2) { [weak self] in
        //     self?.view.setNeedsLayout()
        //     self?.view.layoutIfNeeded()
        //     self?.view.layoutSubviews()
        //     self?.overlayViewController?.view.setNeedsLayout()
        //     self?.overlayViewController?.view.layoutIfNeeded()
        //     self?.overlayViewController?.view.layoutSubviews()
        // }
    }

    private func activateOverlay() {
        let exampleView = ExampleView()
        let overlayViewController: OverlayViewController<ExampleView> = OverlayViewController()
        overlayViewController.add(
            asChildOf: self,
            withHostedView: exampleView,
            animating: true
        ) { hostingView in
            hostingView.backgroundColor = .red
        }
        self.overlayViewController = overlayViewController
    }

    private func deactivateOverlay() {
        self.overlayViewController?.remove(animated: true)
        self.overlayViewController = nil
    }

    @IBAction
    private func toggleOverlay(_ sender: Any) {
        if overlayViewController == nil {
            activateOverlay()
        } else {
            deactivateOverlay()
        }
    }
}
