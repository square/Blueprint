import BlueprintUI
import XCTest
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

    func test_accessibilityElementHiddenNotAccessible() {

        let accessibleView = UIView()
        accessibleView.isAccessibilityElement = true

        let wrapperView = UIView()
        wrapperView.addSubview(accessibleView)
        wrapperView.accessibilityElementsHidden = true

        let containerView = UIView()
        containerView.addSubview(wrapperView)

        let accessibleSubviews = containerView.recursiveAccessibleSubviews() as! [UIView]

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

        let accessibleSubviews = containerView.recursiveAccessibleSubviews() as! [UIView]

        XCTAssertNil(accessibleSubviews.first)
    }

    func test_overrideAccessibility() {
        let label1 = Label(text: "One")
        let label2 = Label(text: "Two")
        let label3 = Label(text: "Three")
        let element = Column {
            label1
            label2
            label3
        }

        let view = BlueprintView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))

        element
            .accessibilityContainer()
            .accessBackingView(in: view) { view in
                let textVals: [String] = view.accessibilityElements!.map {
                    ($0 as! UILabel).text!
                }

                XCTAssertEqual(view.accessibilityElements?.count, 3)
                XCTAssertEqual(textVals, ["One", "Two", "Three"])
            }

        element
            .accessibilityContainer(accessibilityElements: [label1, label3])
            .accessBackingView(in: view) { view in
                let textVals: [String] = view.accessibilityElements!.map {
                    ($0 as! BlueprintUICommonControls.Label).text
                }

                XCTAssertEqual(view.accessibilityElements?.count, 2)
                XCTAssertEqual(textVals, ["One", "Three"])
            }

        element
            .accessibilityContainer(accessibilityElements: [label3, label2, label1])
            .accessBackingView(in: view) { view in
                let textVals: [String] = view.accessibilityElements!.map {
                    ($0 as! BlueprintUICommonControls.Label).text
                }

                XCTAssertEqual(view.accessibilityElements?.count, 3)
                XCTAssertEqual(textVals, ["Three", "Two", "One"])
            }
    }
}
