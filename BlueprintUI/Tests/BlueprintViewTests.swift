import XCTest
@testable import BlueprintUI

class BlueprintViewTests: XCTestCase {

    func test_displaysSimpleView() {

        let blueprintView = BlueprintView(element: SimpleViewElement(color: .red))

        XCTAssert(UIView.self == type(of: blueprintView.currentNativeViewControllers[0].node.view))
        XCTAssertEqual(blueprintView.currentNativeViewControllers[0].node.view.frame, blueprintView.bounds)
    }

    func test_updatesExistingViews() {
        let blueprintView = BlueprintView(element: SimpleViewElement(color: .green))

        let initialView = blueprintView.currentNativeViewControllers[0].node.view
        XCTAssertEqual(initialView.backgroundColor, UIColor.green)

        blueprintView.element = SimpleViewElement(color: .blue)

        XCTAssert(initialView === blueprintView.currentNativeViewControllers[0].node.view)
        XCTAssertEqual(initialView.backgroundColor, UIColor.blue)
    }

    func test_viewOrder() {
        let blueprintView = BlueprintView()

        var tags: [Int]

        blueprintView.element = TestContainer(
            children: [
                TestElement1(tag: 1),
                TestElement1(tag: 2)
            ]
        )

        tags = [1, 2]
        for index in blueprintView.currentNativeViewControllers.indices {
            let node = blueprintView.currentNativeViewControllers[index].node

            let viewAtIndex = node.view.superview!.subviews[index]
            XCTAssertEqual(node.view, viewAtIndex)
            XCTAssertEqual(node.view.tag, tags[index])
        }

        blueprintView.element = TestContainer(
            children: [
                TestElement2(tag: 3),
                TestElement1(tag: 4)
            ]
        )

        tags = [3, 4]
        for index in blueprintView.currentNativeViewControllers.indices {
            let node = blueprintView.currentNativeViewControllers[index].node

            let viewAtIndex = node.view.superview!.subviews[index]
            XCTAssertEqual(node.view, viewAtIndex)
            XCTAssertEqual(node.view.tag, tags[index])
        }
    }

}


fileprivate struct SimpleViewElement: Element {

    var color: UIColor

    var content: ElementContent {
        return ElementContent(intrinsicSize: CGSize(width: 100, height: 100))
    }

    func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return UIView.describe { config in
            config[\.backgroundColor] = color
        }
    }

}

private struct TestElement1: Element {
    var tag: Int

    var content: ElementContent {
        return ElementContent(intrinsicSize: .zero)
    }

    func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return UIView.describe { (config) in
            config[\.tag] = tag
        }
    }
}

private struct TestElement2: Element {
    var tag: Int

    var content: ElementContent {
        return ElementContent(intrinsicSize: .zero)
    }

    func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return UIView.describe { (config) in
            config[\.tag] = tag
        }
    }
}

private struct TestContainer: Element {
    var children: [Element]
    
    var content: ElementContent {
        return ElementContent(layout: TestLayout()) {
            for child in children {
                $0.add(element: child)
            }
        }
    }

    func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return nil
    }

    private class TestLayout: Layout {
        func measure(in constraint: SizeConstraint, items: [(traits: (), content: Measurable)]) -> CGSize {
            return .zero
        }

        func layout(size: CGSize, items: [(traits: (), content: Measurable)]) -> [LayoutAttributes] {
            return Array(repeating: LayoutAttributes(size: .zero), count: items.count)
        }
    }
}
