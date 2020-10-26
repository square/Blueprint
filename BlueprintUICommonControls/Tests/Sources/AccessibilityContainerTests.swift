import XCTest
import BlueprintUI
@testable import BlueprintUICommonControls


class AccessibilityContainerTests: XCTestCase {

    func test_recursiveAccessibleSubviewsIncludesContainedElements() {

        let viewA = UIView()
        let viewB = UIView()

        let innerContainerView = UIView()
        innerContainerView.accessibilityElements = [viewA, viewB]

        let outerContainerView = UIView()
        outerContainerView.addSubview(innerContainerView)

        let accessibleSubviews = outerContainerView.recursiveAccessibleSubviews() as! [UIView]

        XCTAssertEqual(accessibleSubviews.count, 2)
        XCTAssertTrue(accessibleSubviews.contains(where: { $0 === viewA }))
        XCTAssertTrue(accessibleSubviews.contains(where: { $0 === viewB }))
    }

    func test_nestedSubviewsAreFound() {

        let accessibleView = UIView()
        accessibleView.isAccessibilityElement = true

        let wrapperView = UIView()
        wrapperView.addSubview(accessibleView)

        let containerView = UIView()
        containerView.addSubview(wrapperView)

        let accessibleSubviews = containerView.recursiveAccessibleSubviews() as! [UIView]

        XCTAssertEqual(accessibleSubviews[0], accessibleView)
    }

    func test_accessibilityElementsAndContainedViewsAreFound() {

        let viewA = UIView()

        let innerContainerView = UIView()
        innerContainerView.accessibilityElements = [viewA]

        let accessibleView = UIView()
        accessibleView.isAccessibilityElement = true

        let outerContainerView = UIView()
        outerContainerView.addSubview(accessibleView)
        outerContainerView.addSubview(innerContainerView)

        let accessibleSubviews = outerContainerView.recursiveAccessibleSubviews() as! [UIView]

        XCTAssertEqual(accessibleSubviews.count, 2)
        XCTAssertTrue(accessibleSubviews.contains(where: { $0 === viewA }))
        XCTAssertTrue(accessibleSubviews.contains(where: { $0 === accessibleView }))
    }

    func test_searchIsTerminatedAtContainerOrAccessibleView() {
        let undiscoveredViewA = UIView()
        undiscoveredViewA.isAccessibilityElement = true

        let undiscoveredViewB = UIView()
        undiscoveredViewB.isAccessibilityElement = true

        let viewA = UIView()

        let innerContainerView = UIView()
        innerContainerView.accessibilityElements = [viewA]
        innerContainerView.addSubview(undiscoveredViewA)

        let accessibleView = UIView()
        accessibleView.isAccessibilityElement = true
        accessibleView.addSubview(undiscoveredViewB)

        let outerContainerView = UIView()
        outerContainerView.addSubview(accessibleView)
        outerContainerView.addSubview(innerContainerView)

        let accessibleSubviews = outerContainerView.recursiveAccessibleSubviews() as! [UIView]

        XCTAssertEqual(accessibleSubviews.count, 2)
        XCTAssertFalse(accessibleSubviews.contains(where: { $0 === undiscoveredViewA }))
        XCTAssertFalse(accessibleSubviews.contains(where: { $0 === undiscoveredViewB }))
    }
}
