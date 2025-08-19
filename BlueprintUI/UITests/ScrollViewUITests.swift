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

    func test_contentSafeAreaOverlapBehavior_givenOmittedVerticalOverlap() throws {
        try setupScrollView(scrollableAxesSafeAreaEdges: .horizontal) { controller in
            // Decrease the vertical safe area.
            controller.additionalSafeAreaInsets = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
            controller.view.layoutIfNeeded()

            // No bouncing should be enabled because vertical checks are disabled
            // and the content is horizontally within the safe area.
            let uiScrollView = try controller.view.expectedChild(ofType: UIScrollView.self)
            XCTAssertEqual(uiScrollView.safeAreaInsets, UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0))
            XCTAssertFalse(uiScrollView.alwaysBounceVertical)
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

    func test_contentSafeAreaOverlapBehavior_givenOmittedHorizontalOverlap() throws {
        try setupScrollView(scrollableAxesSafeAreaEdges: .vertical) { controller in
            // Decrease the horizontal safe area.
            controller.additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
            controller.view.layoutIfNeeded()

            // No bouncing should be enabled because horizontal checks are disabled
            // and the content is vertically within the safe area.
            let uiScrollView = try controller.view.expectedChild(ofType: UIScrollView.self)
            XCTAssertEqual(uiScrollView.safeAreaInsets, UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10))
            XCTAssertFalse(uiScrollView.alwaysBounceVertical)
            XCTAssertFalse(uiScrollView.alwaysBounceHorizontal)
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
        try setupScrollView(scrollableAxesSafeAreaEdges: []) { controller in
            // Decrease the safe area.
            controller.additionalSafeAreaInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
            controller.view.layoutIfNeeded()

            // No bouncing should be enabled because we're ignoring all safe area edges.
            let uiScrollView = try controller.view.expectedChild(ofType: UIScrollView.self)
            XCTAssertEqual(uiScrollView.safeAreaInsets, UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
            XCTAssertFalse(uiScrollView.alwaysBounceVertical)
            XCTAssertFalse(uiScrollView.alwaysBounceHorizontal)
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
