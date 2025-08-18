import BlueprintUI
import BlueprintUICommonControls
import XCTest

final class ScrollViewUITests: XCTestCase {

    func test_contentSafeAreaOverlapBehavior_givenNoOverlap() throws {
        try setupScrollView { controller in
            // No bouncing should be enabled because content is within the safe area.
            let uiScrollView = try controller.view.expectedChild(ofType: UIScrollView.self)
            XCTAssertEqual(uiScrollView.safeAreaInsets, .zero)
            XCTAssertFalse(uiScrollView.alwaysBounceVertical)
            XCTAssertFalse(uiScrollView.alwaysBounceHorizontal)
        }
    }

    func test_contentSafeAreaOverlapBehavior_givenVerticalOverlap() throws {
        try setupScrollView { controller in
            // Decrease the vertical safe area.
            controller.additionalSafeAreaInsets = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
            controller.view.layoutIfNeeded()

            // Vertical bouncing should be enabled because content is outside the
            // vertical safe area, but inside the ScrollView's bounds.
            let uiScrollView = try controller.view.expectedChild(ofType: UIScrollView.self)
            XCTAssertEqual(uiScrollView.safeAreaInsets, UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0))
            XCTAssertTrue(uiScrollView.alwaysBounceVertical)
            XCTAssertFalse(uiScrollView.alwaysBounceHorizontal)
        }
    }

    func test_contentSafeAreaOverlapBehavior_givenHorizontalOverlap() throws {
        try setupScrollView { controller in
            // Decrease the horizontal safe area.
            controller.additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
            controller.view.layoutIfNeeded()

            // Horizontal bouncing should be enabled because content is outside the
            // horizontal safe area, but inside the ScrollView's bounds.
            let uiScrollView = try controller.view.expectedChild(ofType: UIScrollView.self)
            XCTAssertEqual(uiScrollView.safeAreaInsets, UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10))
            XCTAssertFalse(uiScrollView.alwaysBounceVertical)
            XCTAssertTrue(uiScrollView.alwaysBounceHorizontal)
        }
    }

    func test_contentSafeAreaOverlapBehavior_givenOutsideScrollViewBounds() throws {
        try setupScrollView(testSize: CGSize(width: 9999, height: 9999)) { controller in
            // No bouncing should be enabled because content is outside the bounds
            // of the scroll view.
            let uiScrollView = try controller.view.expectedChild(ofType: UIScrollView.self)
            XCTAssertEqual(uiScrollView.safeAreaInsets, .zero)
            XCTAssertFalse(uiScrollView.alwaysBounceVertical)
            XCTAssertFalse(uiScrollView.alwaysBounceHorizontal)
        }
    }

    func test_contentSafeAreaOverlapBehavior_givenIgnoredSafeArea() throws {
        try setupScrollView(contentSafeAreaOverlapBehavior: .ignoreSafeArea) { controller in
            // Decrease the safe area.
            controller.additionalSafeAreaInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
            controller.view.layoutIfNeeded()

            // No bouncing should be enabled because we're ignoring the safe area.
            let uiScrollView = try controller.view.expectedChild(ofType: UIScrollView.self)
            XCTAssertEqual(uiScrollView.safeAreaInsets, UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
            XCTAssertFalse(uiScrollView.alwaysBounceVertical)
            XCTAssertFalse(uiScrollView.alwaysBounceHorizontal)
        }
    }

    func setupScrollView(
        contentSafeAreaOverlapBehavior: ScrollView.ContentSafeAreaOverlapBehavior = .includeSafeArea,
        testSize: CGSize? = nil,
        _ test: (UIViewController
        ) throws -> Void
    ) throws {
        try show(vc: UIViewController()) { controller in
            // Pick a frame for the ScrollView that is completely inside the safe area.
            let scrollViewFrame = controller.view.safeAreaLayoutGuide.layoutFrame

            // Make the content smaller than the ScrollView's bounds by default.
            let content = Box().constrainedTo(
                size: testSize ?? CGSize(
                    width: scrollViewFrame.width - 1,
                    height: scrollViewFrame.height - 1
                )
            )
            let scrollView = ScrollView(.fittingContent, wrapping: content) { scrollView in
                scrollView.contentInsetAdjustmentBehavior = .scrollableAxes
                scrollView.contentSafeAreaOverlapBehavior = contentSafeAreaOverlapBehavior
            }
            let containerView = BlueprintView(element: scrollView)
            containerView.frame = scrollViewFrame
            controller.view.addSubview(containerView)
            containerView.layoutIfNeeded()

            try test(controller)
        }
    }
}
