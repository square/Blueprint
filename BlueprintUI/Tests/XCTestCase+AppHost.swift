import BlueprintUI
import UIKit
import XCTest


extension XCTestCase {

    ///
    /// Call this method to show a view controller in the test host application
    /// during a unit test. The view controller will be the size of host application's device.
    ///
    /// After the test runs, the view controller will be removed from the view hierarchy.
    ///
    /// A test failure will occur if the host application does not exist, or does not have a root view controller.
    ///
    public func show<ViewController: UIViewController>(
        vc viewController: ViewController,
        loadAndPlaceView: Bool = true,
        test: (ViewController) throws -> Void
    ) rethrows {

        var temporaryWindow: UIWindow? = nil

        func rootViewController() -> UIViewController {
            if let rootVC = UIApplication.shared.delegate?.window??.rootViewController {
                return rootVC
            } else {
                let window = UIWindow(frame: UIScreen.main.bounds)
                let rootVC = UIViewController()
                window.rootViewController = rootVC
                window.makeKeyAndVisible()

                temporaryWindow = window

                return rootVC
            }
        }

        let rootVC = rootViewController()

        rootVC.addChild(viewController)
        viewController.didMove(toParent: rootVC)

        if loadAndPlaceView {
            viewController.view.frame = rootVC.view.bounds
            viewController.view.layoutIfNeeded()

            rootVC.beginAppearanceTransition(true, animated: false)
            rootVC.view.addSubview(viewController.view)
            rootVC.endAppearanceTransition()
        }

        defer {
            if loadAndPlaceView {
                viewController.beginAppearanceTransition(false, animated: false)
                viewController.view.removeFromSuperview()
                viewController.endAppearanceTransition()
            }

            viewController.willMove(toParent: nil)
            viewController.removeFromParent()

            if let window = temporaryWindow {
                window.resignKey()
                window.isHidden = true

                window.rootViewController = nil
            }
        }

        try autoreleasepool {
            try test(viewController)
        }
    }

    /// Runs the given block with a `BlueprintView` that is hosted in in a view controller in the
    /// app host's window. You can use this to test elements that require some UIKit interaction,
    /// like focus.
    public func withHostedView(test: (BlueprintView) -> Void) {
        final class TestViewController: UIViewController {
            let blueprintView = BlueprintView()

            override func loadView() {
                view = blueprintView
            }
        }

        let viewController = TestViewController()

        show(vc: viewController) { _ in
            test(viewController.blueprintView)
        }
    }
}
