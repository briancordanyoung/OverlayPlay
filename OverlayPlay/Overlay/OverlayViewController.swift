import UIKit
import SwiftUI
import OverlayKit

public class OverlayViewController<V: View>: UIViewController {
    public var padding: CGFloat {
        get { constraints.padding }
        set { constraints.padding = newValue }
    }
    /// The padding needed to fill the area below the safe area guide on a iPhone X class phone.
    public var additionalBottomPadding: CGFloat {
        get { constraints.additionalBottomPadding }
        set { constraints.additionalBottomPadding = newValue }
    }

    public typealias ViewConfigurator = (UIView) -> Void
    public var viewConfigurator: ViewConfigurator = { _ in }

    private var hostingController: UIHostingController<V>?
    private var constraints = Constraints()
    private var lastNotificationInfo: OverlayViewController.NotificationInfo?

    public func add(
        asChildOf parentViewController: UIViewController,
        withHostedView hostedView: V,
        animating animated: Bool = true,
        configuringOverlayView configureView: ViewConfigurator? = nil
    ) {
        let childViewController = self
        guard
            let superview = parentViewController.view,
            let overlayView = view
        else {
            let msg = "OverlayViewController.add(asChildOf:) called before views were loaded."
            assertionFailure(msg)
            return
        }

        let configureView = configureView ?? self.viewConfigurator
        configureView(overlayView)

        hostingController = UIHostingController(rootView: hostedView)
        guard let hostingView = hostingController?.view else {
            let msg = "OverlayViewController.add(asChildOf:) called before views were loaded."
            assertionFailure(msg)
            return
        }

        parentViewController.addChild(childViewController)
        superview.addSubview(overlayView)
        overlayView.addSubview(hostingView)

        overlayView.translatesAutoresizingMaskIntoConstraints = false
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        constraints.overlaySetup(between: overlayView, andSuperview: superview)
        constraints.hostingSetup(between: hostingView, andOverlayView: overlayView)
        constraints.hostingSetup(between: hostingView, andSuperview: superview)
        constraints.hostingSetup(hostingView)

        childViewController.didMove(toParent: parentViewController)

        hostingView.backgroundColor = .orange

        activate(animated: animated)
    }

    private func activate(animated: Bool) {
        guard let superview = view.superview else { return }
        superview.layoutIfNeeded()

        notify(newHeight: superview.frame.height, animated: animated)

        constraints.activateOnScreen()
        if animated {
            superview.animateLayoutIfNeeded()
        } else {
            superview.layoutIfNeeded()
        }
    }

    public func remove(animated: Bool = false) {
        guard let superview = view.superview else { return }
        notify(newHeight: -1, animated: animated)

        constraints.activateOffScreen()
        if animated {
            superview.animateLayoutIfNeeded({ self.removeAsChildViewController() })
        } else {
            removeAsChildViewController()
        }
    }

    private func removeAsChildViewController() {
        willMove(toParent: nil)
        constraints.remove()
        view.removeFromSuperview()
        removeFromParent()
        hostingController = nil
    }

    private func notify(newHeight: CGFloat, animated: Bool = false) {
        if animated {
            notify(newHeight: newHeight, withDuration: Overlay.Animation.duration, options: Overlay.Animation.options)
        } else {
            notify(newHeight: newHeight, withDuration: 0, options: .curveLinear)
        }
    }
    /// Publish a notice to the NotificationCenter that the toast will change height.
    /// - Parameters:
    ///   - newHeight: The new height the toast will animate to
    ///   - duration: The duration of the animation
    ///   - options: The animation options effecting the curve of the animation.
    private func notify(
        newHeight: CGFloat,
        withDuration duration: TimeInterval,
        options: UIView.AnimationOptions
    ) {
        let overlayNotificationInfo = OverlayViewController.NotificationInfo(
            newHeight: newHeight,
            animationDuration: duration,
            animationOptions: options
        )

        defer { lastNotificationInfo = overlayNotificationInfo }

        // If there is no change in height, skip sending the notification
        guard let oldHeight = lastNotificationInfo?.newHeight, oldHeight != newHeight else { return }

        NotificationCenter.default.post(
            name: Overlay.willChangeFrameNotification,
            object: nil,
            userInfo: [Overlay.notificationInfo: overlayNotificationInfo]
        )
    }
}

// MARK: - Notification
extension OverlayViewController {
    public struct NotificationInfo {
        public var newHeight: CGFloat
        public var animationDuration: TimeInterval
        public var animationOptions: UIView.AnimationOptions
    }
}

// MARK: - Private

// MARK: Private Constraint Structs
extension OverlayViewController {
    fileprivate struct Constraints {
        fileprivate var padding: CGFloat = 16 {
            didSet { updateHostingViewPadding() }
        }
        /// The padding needed to fill the area below the safe area guide on a iPhone X class phone.
        fileprivate var additionalBottomPadding: CGFloat = 34 {
            didSet { updateHostingViewPadding() }
        }

        fileprivate var betweenOverlayAndSuperView   = BetweenOverlayAndSuperView()
        fileprivate var betweenHostingAndOverlayView = BetweenHostedAndOverlayView()
        fileprivate var betweenHostedAndSuperView    = BetweenHostedAndSuperView()

        fileprivate mutating func activateOnScreen() {
            betweenHostedAndSuperView.onScreen.isActive   = true
            betweenOverlayAndSuperView.offScreen.isActive = false
        }

        fileprivate mutating func activateOffScreen() {
            betweenHostedAndSuperView.onScreen.isActive   = false
            betweenOverlayAndSuperView.offScreen.isActive = true
        }

        fileprivate mutating func remove() {
            betweenOverlayAndSuperView.remove()
            betweenHostingAndOverlayView.remove()
            betweenHostedAndSuperView.remove()
        }

        fileprivate mutating func overlaySetup(between overlayView: UIView, andSuperview superview: UIView) {
            overlayView.setContentCompressionResistancePriority(.required, for: .vertical)
            overlayView.setContentHuggingPriority(.init(1), for: .vertical)

            let offScreenConstraint              = overlayView.topAnchor.constraint(equalTo: superview.bottomAnchor)
            offScreenConstraint.identifier       = "OverlayViewOffScreenConstraint"

            betweenOverlayAndSuperView.offScreen.replace(offScreenConstraint)
            betweenOverlayAndSuperView.leading.replace( overlayView.leadingAnchor.constraint(equalTo: superview.leadingAnchor) )
            betweenOverlayAndSuperView.trailing.replace( overlayView.trailingAnchor.constraint(equalTo: superview.trailingAnchor) )
        }

        fileprivate mutating func hostingSetup(between hostingView: UIView, andOverlayView overlayView: UIView) {
            betweenHostingAndOverlayView.top.replace( overlayView.topAnchor.constraint(equalTo: hostingView.topAnchor) )
            betweenHostingAndOverlayView.leading.replace( overlayView.leadingAnchor.constraint(equalTo: hostingView.leadingAnchor) )
            betweenHostingAndOverlayView.trailing.replace( overlayView.trailingAnchor.constraint(equalTo: hostingView.trailingAnchor) )
            betweenHostingAndOverlayView.bottom.replace( overlayView.bottomAnchor.constraint(equalTo: hostingView.bottomAnchor) )
            betweenHostingAndOverlayView.center.replace( overlayView.centerXAnchor.constraint(equalTo: hostingView.centerXAnchor) )
            updateHostingViewPadding()
        }

        fileprivate mutating func hostingSetup(_ hostingView: UIView) {
            hostingView.setContentCompressionResistancePriority(.init(1), for: .vertical)
            hostingView.setContentHuggingPriority(.required, for: .vertical)
        }

        fileprivate mutating func hostingSetup(between hostingView: UIView, andSuperview superview: UIView) {
            let safeAreaLayoutGuideBottom      = superview.safeAreaLayoutGuide.bottomAnchor
            let onScreenConstraint             = hostingView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuideBottom, constant: 0)
            onScreenConstraint.identifier      = "OverlayViewOnScreenConstraint"
            onScreenConstraint.priority        = .init(999)
            betweenHostedAndSuperView.onScreen.replace(onScreenConstraint)
            onScreenConstraint.isActive        = false
            updateHostingViewPadding()
        }

        fileprivate mutating func updateHostingViewPadding() {
            betweenHostedAndSuperView.onScreen.constant    = padding * -1
            betweenHostingAndOverlayView.top.constant      = padding * -1
            betweenHostingAndOverlayView.leading.constant  = padding * -1
            betweenHostingAndOverlayView.trailing.constant = padding
            betweenHostingAndOverlayView.bottom.constant   = padding + additionalBottomPadding
        }
    }
}

extension OverlayViewController.Constraints {
    fileprivate struct BetweenHostedAndOverlayView {
        fileprivate var top: NSLayoutConstraint?
        fileprivate var leading: NSLayoutConstraint?
        fileprivate var trailing: NSLayoutConstraint?
        fileprivate var bottom: NSLayoutConstraint?
        fileprivate var center: NSLayoutConstraint?

        fileprivate mutating func remove() {
            top.remove()
            leading.remove()
            trailing.remove()
            bottom.remove()
            center.remove()
        }
    }
}

extension OverlayViewController.Constraints {
    fileprivate struct BetweenHostedAndSuperView {
        fileprivate var onScreen: NSLayoutConstraint?

        fileprivate mutating func remove() {
            onScreen.remove()
        }
    }
}

extension OverlayViewController.Constraints {
    fileprivate struct BetweenOverlayAndSuperView {
        fileprivate var leading: NSLayoutConstraint?
        fileprivate var trailing: NSLayoutConstraint?
        fileprivate var offScreen: NSLayoutConstraint?

        fileprivate mutating func remove() {
            leading.remove()
            trailing.remove()
            offScreen.remove()
        }
    }
}

// MARK: Private Helper Extensions
extension Optional where Wrapped == NSLayoutConstraint {
    /// Set the value to the new constraint and activate it. If a current constraint exists, deactivate it before replacing it.
    /// - Parameter newConstraint: The new NSLayoutConstraint
    fileprivate mutating func replace(_ newConstraint: NSLayoutConstraint) {
        if let oldConstraint = self {
            oldConstraint.isActive = false
        }
        self = newConstraint
        newConstraint.isActive = true
    }
    /// Deactivate the constraint and set the value to `nil`
    fileprivate mutating func remove() {
        if let oldConstraint = self {
            oldConstraint.isActive = false
            self = nil
        }
    }
    /// The constant added to the multiplied second attribute participating in the constraint.
    ///
    /// Unlike the other properties, the constant can be modified after constraint creation.
    /// Setting the constant on an existing constraint performs much better than removing
    /// the constraint and adding a new one that's exactly like the old except that it has a different constant.
    fileprivate var constant: CGFloat? {
        get { self?.constant }
        set {
            guard
                let constraint = self,
                let value = newValue
            else { return }
            constraint.constant = value
        }
    }
    /// The active state of the constraint.
    ///
    /// You can activate or deactivate a constraint by changing this property.
    /// Note that only active constraints affect the calculated layout.
    /// If you try to activate a constraint whose items have no common ancestor, an exception is thrown.
    /// For newly created constraints, the isActive property is false by default.
    /// Activating or deactivating the constraint calls addConstraint(_:) and removeConstraint(_:)
    /// on the view that is the closest common ancestor of the items managed by this constraint.
    /// Use this property instead of calling addConstraint(_:) or removeConstraint(_:) directly.
    fileprivate var isActive: Bool? {
        get { self?.isActive }
        set {
            guard
                let constraint = self,
                let value = newValue
            else { return }
            constraint.isActive = value
        }
    }
}

extension UIView {
    fileprivate func animateLayoutIfNeeded(_ completion: @escaping VoidClosure = {}) {
        UIView.animate(
            withDuration: Overlay.Animation.duration,
            delay: 0,
            options: Overlay.Animation.options,
            animations: { self.layoutIfNeeded() },
            completion: { _ in completion() }
        )
    }
}

extension Overlay {
    fileprivate enum Animation {
        fileprivate static let duration: TimeInterval = 0.25
        fileprivate static let options: UIView.AnimationOptions = .curveEaseInOut
    }
}
