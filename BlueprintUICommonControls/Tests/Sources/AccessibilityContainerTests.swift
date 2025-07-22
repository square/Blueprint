import BlueprintUI
import XCTest
@testable import BlueprintUICommonControls


class AccessibilityContainerTests: XCTestCase {

    func test_recursiveAccessibleSubviewsIncludesContainedElements() {

        let viewA = UIView()
        let viewB = UIView()

        viewA.isAccessibilityElement = true
        viewB.isAccessibilityElement = true

        let innerContainerView = UIView()
        innerContainerView.accessibilityElements = [viewA, viewB]

        let outerContainerView = UIView()
        outerContainerView.addSubview(innerContainerView)

        let accessibleSubviews = outerContainerView.accessibilityElements(layoutDirection: .leftToRight) as! [UIView]

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

        let accessibleSubviews = containerView.accessibilityElements(layoutDirection: .leftToRight) as! [UIView]

        XCTAssertEqual(accessibleSubviews[0], accessibleView)
    }

    func test_searchIsTerminatedAtAccessibleViewButContinuesIntoNonAccessibleContainerElements() {
        let deeplyNestedAccessible = UIView()
        deeplyNestedAccessible.isAccessibilityElement = true

        let nonAccessibleContainerElement = UIView()
        nonAccessibleContainerElement.addSubview(deeplyNestedAccessible)

        let undiscoveredViewB = UIView()
        undiscoveredViewB.isAccessibilityElement = true

        let innerContainerView = UIView()
        // This container has a non-accessible UIView element that should be recursively processed
        innerContainerView.accessibilityElements = [nonAccessibleContainerElement]

        let accessibleView = UIView()
        accessibleView.isAccessibilityElement = true
        // This accessible view's children should not be discovered since search stops at accessibility elements
        accessibleView.addSubview(undiscoveredViewB)

        let outerContainerView = UIView()
        outerContainerView.addSubview(accessibleView)
        outerContainerView.addSubview(innerContainerView)

        let accessibleSubviews = outerContainerView.accessibilityElements(layoutDirection: .leftToRight) as! [UIView]

        XCTAssertEqual(accessibleSubviews.count, 2)
        // Should find the deeply nested accessible view through recursive processing
        XCTAssertTrue(accessibleSubviews.contains(where: { $0 === deeplyNestedAccessible }))
        XCTAssertTrue(accessibleSubviews.contains(where: { $0 === accessibleView }))
        // Should NOT find this because search stops at accessible views
        XCTAssertFalse(accessibleSubviews.contains(where: { $0 === undiscoveredViewB }))
    }

    func test_recursiveProcessingOfAccessibilityElementsUIViews() {
        // Create a hierarchy where accessibilityElements contains UIViews that need further processing
        let finalAccessibleView = UIView()
        finalAccessibleView.isAccessibilityElement = true

        let intermediateContainer = UIView()
        intermediateContainer.addSubview(finalAccessibleView)

        let parentContainer = UIView()
        // The accessibility elements list contains a UIView that is not an accessibility element itself
        // but contains accessible elements within it
        parentContainer.accessibilityElements = [intermediateContainer]

        let rootContainer = UIView()
        rootContainer.addSubview(parentContainer)

        let accessibleSubviews = rootContainer.accessibilityElements(layoutDirection: .leftToRight) as! [UIView]

        XCTAssertEqual(accessibleSubviews.count, 1)
        XCTAssertTrue(accessibleSubviews.contains(where: { $0 === finalAccessibleView }))
    }

    func test_mixedAccessibilityElementsWithAccessibleAndNonAccessibleUIViews() {
        let directAccessibleView = UIView()
        directAccessibleView.isAccessibilityElement = true

        let deeplyNestedAccessible = UIView()
        deeplyNestedAccessible.isAccessibilityElement = true

        let nonAccessibleContainer = UIView()
        nonAccessibleContainer.addSubview(deeplyNestedAccessible)

        let parentContainer = UIView()
        // Mix of directly accessible UIView and UIView that needs recursive processing
        parentContainer.accessibilityElements = [directAccessibleView, nonAccessibleContainer]

        let rootContainer = UIView()
        rootContainer.addSubview(parentContainer)

        let accessibleSubviews = rootContainer.accessibilityElements(layoutDirection: .leftToRight) as! [UIView]

        XCTAssertEqual(accessibleSubviews.count, 2)
        XCTAssertTrue(accessibleSubviews.contains(where: { $0 === directAccessibleView }))
        XCTAssertTrue(accessibleSubviews.contains(where: { $0 === deeplyNestedAccessible }))
    }

    func test_accessibilityElementHiddenNotAccessible() {

        let accessibleView = UIView()
        accessibleView.isAccessibilityElement = true

        let wrapperView = UIView()
        wrapperView.addSubview(accessibleView)
        wrapperView.accessibilityElementsHidden = true

        let containerView = UIView()
        containerView.addSubview(wrapperView)

        let accessibleSubviews = containerView.accessibilityElements(layoutDirection: .leftToRight) as! [UIView]

        XCTAssertNil(accessibleSubviews.first)
    }

    func test_isHiddenNotAccessible() {

        let accessibleView = UIView()
        accessibleView.isAccessibilityElement = true

        let wrapperView = UIView()
        wrapperView.addSubview(accessibleView)
        wrapperView.isHidden = true

        let containerView = UIView()
        containerView.addSubview(wrapperView)

        let accessibleSubviews = containerView.accessibilityElements(layoutDirection: .leftToRight) as! [UIView]

        XCTAssertNil(accessibleSubviews.first)
    }

    func test_elements_override() {

        let accessibleView = UIView()
        accessibleView.isAccessibilityElement = true

        let containerView = AccessibilityContainer.AccessibilityContainerView()
        containerView.addSubview(accessibleView)

        let elements = containerView.accessibilityElements

        XCTAssertEqual(elements?.first as? UIView, accessibleView)

        let overrideElement = NSObject()
        overrideElement.isAccessibilityElement = true

        containerView.elements = [overrideElement]

        let overriden = containerView.accessibilityElements
        XCTAssertEqual(overriden?.first as? NSObject, overrideElement)

    }
}
