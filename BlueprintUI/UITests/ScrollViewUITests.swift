import BlueprintUI
import BlueprintUICommonControls
import XCTest

final class ScrollViewUITests: XCTestCase {

    func test_scrollableAxesSafeAreaEdges_givenNoOverlap() throws {
        try setupScrollView { controller in
            // No contentInset should be applied because the content is within the safe area.
            let uiScrollView = try controller.view.expectedChild(ofType: UIScrollView.self)
            XCTAssertEqual(uiScrollView.contentInset, .zero)
        }
    }

    func test_scrollableAxesSafeAreaEdges_givenVerticalOverlap() throws {
        try setupScrollView { controller in
            // Decrease the vertical safe area.
            controller.additionalSafeAreaInsets = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
            controller.view.layoutIfNeeded()

            // The contentInset should be adjusted to reach the safe area.
            let uiScrollView = try controller.view.expectedChild(ofType: UIScrollView.self)
            XCTAssertEqual(uiScrollView.contentInset, UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0))
        }
    }

    func test_scrollableAxesSafeAreaEdges_givenHorizontalOverlap() throws {
        try setupScrollView { controller in
            // Decrease the horizontal safe area.
            controller.additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
            controller.view.layoutIfNeeded()

            // The contentInset should be adjusted to reach the safe area.
            let uiScrollView = try controller.view.expectedChild(ofType: UIScrollView.self)
            XCTAssertEqual(uiScrollView.contentInset, UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10))
        }
    }

    func test_scrollableAxesSafeAreaEdges_givenAllOverlap() throws {
        try setupScrollView { controller in
            // Decrease the vertical safe area.
            controller.additionalSafeAreaInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
            controller.view.layoutIfNeeded()

            // The contentInset should be adjusted to reach the safe area.
            let uiScrollView = try controller.view.expectedChild(ofType: UIScrollView.self)
            XCTAssertEqual(uiScrollView.contentInset, UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
        }
    }

    func test_scrollableAxesSafeAreaEdges_givenBottomOverlap() throws {
        try setupScrollView(scrollableAxesSafeAreaEdges: .bottom) { controller in
            // Decrease the vertical safe area.
            controller.additionalSafeAreaInsets = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
            controller.view.layoutIfNeeded()

            // Only the bottom contentInset should be adjusted to reach the safe area.
            let uiScrollView = try controller.view.expectedChild(ofType: UIScrollView.self)
            XCTAssertEqual(uiScrollView.contentInset, UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0))
        }
    }

    func test_scrollableAxesSafeAreaEdges_givenRightOverlap() throws {
        try setupScrollView(scrollableAxesSafeAreaEdges: .right) { controller in
            // Decrease the horizontal safe area.
            controller.additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
            controller.view.layoutIfNeeded()

            // Only the right contentInset should be adjusted to reach the safe area.
            let uiScrollView = try controller.view.expectedChild(ofType: UIScrollView.self)
            XCTAssertEqual(uiScrollView.contentInset, UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10))
        }
    }

    func test_scrollableAxesSafeAreaEdges_givenOmittedVerticalOverlap() throws {
        try setupScrollView(scrollableAxesSafeAreaEdges: .horizontal) { controller in
            // Decrease the safe area on all sides.
            controller.additionalSafeAreaInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
            controller.view.layoutIfNeeded()

            // Only the horizontal contentInset should be adjusted to reach the safe area.
            let uiScrollView = try controller.view.expectedChild(ofType: UIScrollView.self)
            XCTAssertEqual(uiScrollView.contentInset, UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10))
        }
    }

    func test_scrollableAxesSafeAreaEdges_givenOmittedHorizontalOverlap() throws {
        try setupScrollView(scrollableAxesSafeAreaEdges: .vertical) { controller in
            // Decrease the safe area on all sides.
            controller.additionalSafeAreaInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
            controller.view.layoutIfNeeded()

            // Only the vertical contentInset should be adjusted to reach the safe area.
            let uiScrollView = try controller.view.expectedChild(ofType: UIScrollView.self)
            XCTAssertEqual(uiScrollView.contentInset, UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0))
        }
    }

    func test_scrollableAxesSafeAreaEdges_givenOutsideScrollViewBounds() throws {
        try setupScrollView(testSize: CGSize(width: 9999, height: 9999)) { controller in
            // No contentInset should be applied because the content is outside the bounds
            // of the scroll view.
            let uiScrollView = try controller.view.expectedChild(ofType: UIScrollView.self)
            XCTAssertEqual(uiScrollView.contentInset, .zero)
        }
    }

    func test_scrollableAxesSafeAreaEdges_givenIgnoredSafeArea() throws {
        try setupScrollView(scrollableAxesSafeAreaEdges: []) { controller in
            // Decrease the safe area on all sides.
            controller.additionalSafeAreaInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
            controller.view.layoutIfNeeded()

            // No contentInset should be applied because we're ignoring all safe area edges.
            let uiScrollView = try controller.view.expectedChild(ofType: UIScrollView.self)
            XCTAssertEqual(uiScrollView.contentInset, .zero)
        }
    }

    func setupScrollView(
        scrollableAxesSafeAreaEdges: ScrollView.SafeAreaEdge = .all,
        testSize: CGSize? = nil,
        _ test: (UIViewController
        ) throws -> Void
    ) throws {
        try show(vc: UIViewController()) { controller in
            // Pick a frame for the ScrollView that is completely inside the safe area.
            let scrollViewFrame = controller.view.safeAreaLayoutGuide.layoutFrame

            // Make the content equal to the ScrollView's bounds by default.
            let content = Box().constrainedTo(size: testSize ?? scrollViewFrame.size)
            let scrollView = ScrollView(.fittingContent, wrapping: content) { scrollView in
                scrollView.contentInsetAdjustmentBehavior = .scrollableAxes
                scrollView.scrollableAxesSafeAreaEdges = scrollableAxesSafeAreaEdges
            }
            let containerView = BlueprintView(element: scrollView)
            containerView.frame = scrollViewFrame
            controller.view.addSubview(containerView)
            containerView.layoutIfNeeded()

            try test(controller)
        }
    }
}
