import AccessibilitySnapshot
import BlueprintUI
import SnapshotTesting
import UIKit
import XCTest

extension XCTestCase {

    /// Accessibility snapshot testing for Blueprint elements with view controller hosting.
    ///
    /// This method creates a UIViewController containing a BlueprintView with the provided element,
    /// hosts it in the test application window, and performs accessibility snapshot testing with
    /// automatic filename generation in the format: {test name}_{ios version}_{screen size}@{screen scale}x
    ///
    /// The hosted approach ensures proper accessibility hierarchy, view controller lifecycle,
    /// and window presentation context for accurate accessibility testing.
    ///
    /// Example generated filenames:
    /// - test_label_accessibility_snapshot_18.0_393x852@3x.png
    /// - test_button_accessibility_snapshot_18.0_393x852@3x.png
    /// - custom_test_name.png (when name is provided)
    ///
    /// - Parameters:
    ///   - element: The Blueprint Element to snapshot
    ///   - snapshotting: The snapshotting strategy (defaults to .accessibilityImage)
    ///   - name: Optional custom name override. If provided, automatic naming is skipped
    ///   - recording: Whether to record new snapshots
    ///   - timeout: Timeout for snapshot generation
    ///   - fileID: File identifier (automatically provided)
    ///   - filePath: File path (automatically provided)
    ///   - testName: Test function name (automatically provided)
    ///   - line: Line number (automatically provided)
    ///   - column: Column number (automatically provided)
    func assertAccessibilitySnapshot<Format>(
        of element: Element,
        as snapshotting: Snapshotting<UIView, Format> = .accessibilityImage,
        named name: String? = nil,
        record recording: Bool? = nil,
        timeout: TimeInterval = 5,
        fileID: StaticString = #fileID,
        file filePath: StaticString = #filePath,
        testName: String = #function,
        line: UInt = #line,
        column: UInt = #column
    ) {
        let testViewController = createTestViewController(with: element)
        let customName = name ?? generateSnapshotMetadate()

        show(vc: testViewController) { viewController in
            // Snapshot just the BlueprintView, not the entire view controller
            assertSnapshot(
                of: viewController.blueprintView,
                as: .accessibilityImage,
                named: customName,
                record: recording,
                timeout: timeout,
                fileID: fileID,
                file: filePath,
                testName: testName,
                line: line,
                column: column
            )
        }
    }

    // MARK: - Private Helper Methods

    /// Generates a snapshot filename with device and iOS version information.
    ///
    /// Creates filenames in the format: {test name}_{ios version}_{screen size}@{screen scale}x
    ///
    /// Example output: "test_label_accessibility_snapshot_18.0_393x852@3x"
    ///
    /// - Parameter testName: The test function name (typically from #function)
    /// - Returns: A formatted filename string with device information
    private func generateSnapshotMetadate() -> String {
        // Get device information
        let screen = UIScreen.main
        let screenSize = screen.bounds.size
        let screenScale = screen.scale
        let iosVersion = ProcessInfo.processInfo.operatingSystemVersion

        // Format screen size as "widthxheight"
        let screenSizeString = "\(Int(screenSize.width))x\(Int(screenSize.height))"

        // Format iOS version as "major.minor"
        let iosVersionString = "\(iosVersion.majorVersion)-\(iosVersion.minorVersion)"

        // Create the filename: {test name}_{ios version}_{screen size}@{screen scale}x
        return "\(iosVersionString)_\(screenSizeString)@\(Int(screenScale))x"
    }

    /// Show a view controller in the test host application during a unit test.
    /// This is a simplified version of the show(vc:) method from XCTestCase+AppHost.
    private func show<ViewController: UIViewController>(
        vc viewController: ViewController,
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

        viewController.view.frame = rootVC.view.bounds
        viewController.view.layoutIfNeeded()

        viewController.beginAppearanceTransition(true, animated: false)
        rootVC.view.addSubview(viewController.view)
        viewController.endAppearanceTransition()

        defer {
            viewController.beginAppearanceTransition(false, animated: false)
            viewController.view.removeFromSuperview()
            viewController.endAppearanceTransition()

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

    /// Creates a UIViewController from a Blueprint Element for testing purposes.
    ///
    /// This method wraps the provided Element in a BlueprintView and hosts it in a
    /// UIViewController to ensure proper accessibility hierarchy and view controller
    /// lifecycle for snapshot testing. The BlueprintView is added as a subview so it
    /// can size itself to its content rather than filling the entire screen.
    ///
    /// - Parameter element: The Blueprint Element to convert to a UIViewController
    /// - Returns: A UIViewController containing the element with proper accessibility setup
    private func createTestViewController(with element: Element) -> TestViewController {
        let viewController = TestViewController()
        viewController.blueprintView.element = element

        // Ensure the view is loaded and laid out
        _ = viewController.view
        viewController.view.setNeedsLayout()
        viewController.view.layoutIfNeeded()

        return viewController
    }
}

/// Test view controller that hosts a BlueprintView for accessibility snapshot testing.
private final class TestViewController: UIViewController {
    let blueprintView = BlueprintView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        // Add BlueprintView as a subview so it can size to its content
        view.addSubview(blueprintView)

        // Center the BlueprintView in the container
        blueprintView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            blueprintView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            blueprintView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
}
