import XCTest
@testable import BlueprintUI

class BlueprintViewTests: XCTestCase {
    
    func test_sizeThatFits() {
        
        /// NOTE: References to `.greatestFiniteMagnitude` always refer to the fully qualified type,
        /// `CGFloat.greatestFiniteMagnitude` to ensure we are not implicitly comparing against doubles,
        /// which have a different underlying type on 32 bit devices.
        
        let blueprintView = BlueprintView()
        
        // Normal sizes.
        
        do {
            let element = MeasurableElement { constraint in
                XCTAssertEqual(constraint.maximum, CGSize(width: 200, height: 100))
                return CGSize(width: 100, height: 50)
            }
            
            blueprintView.element = element
            
            XCTAssertEqual(blueprintView.sizeThatFits(CGSize(width: 200, height: 100)), CGSize(width: 100, height: 50))
        }
        
        // Unconstrained in both axes.
        
        do {
            let element = MeasurableElement { constraint in
                XCTAssertEqual(constraint.width, .unconstrained)
                XCTAssertEqual(constraint.height, .unconstrained)
                XCTAssertEqual(constraint.maximum, CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
                
                return CGSize(width: 100, height: 50)
            }
            
            blueprintView.element = element
            
            XCTAssertEqual(blueprintView.sizeThatFits(.zero), CGSize(width: 100, height: 50))
            XCTAssertEqual(blueprintView.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)), CGSize(width: 100, height: 50))
            XCTAssertEqual(blueprintView.sizeThatFits(CGSize(width: CGFloat.infinity, height: CGFloat.infinity)), CGSize(width: 100, height: 50))
        }
        
        // Unconstrained in one axis only.
        
        do {
            // X
            
            do {
                let element = MeasurableElement { constraint in
                    XCTAssertEqual(constraint.width, .unconstrained)
                    XCTAssertEqual(constraint.height.maximum, 100.0)
                    XCTAssertEqual(constraint.maximum, CGSize(width: CGFloat.greatestFiniteMagnitude, height: 100.0))
                    
                    return CGSize(width: 100, height: 50)
                }
                
                blueprintView.element = element
                
                XCTAssertEqual(blueprintView.sizeThatFits(CGSize(width: 0.0, height: 100.0)), CGSize(width: 100, height: 50))
                XCTAssertEqual(blueprintView.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: 100.0)), CGSize(width: 100, height: 50))
                XCTAssertEqual(blueprintView.sizeThatFits(CGSize(width: CGFloat.infinity, height: 100.0)), CGSize(width: 100, height: 50))
            }
            
            // Y
            
            do {
                let element = MeasurableElement { constraint in
                    XCTAssertEqual(constraint.width.maximum, 100.0)
                    XCTAssertEqual(constraint.height, .unconstrained)
                    XCTAssertEqual(constraint.maximum, CGSize(width: 100.0, height: CGFloat.greatestFiniteMagnitude))
                    
                    return CGSize(width: 100, height: 50)
                }
                
                blueprintView.element = element
                
                XCTAssertEqual(blueprintView.sizeThatFits(CGSize(width: 100.0, height: 0.0)), CGSize(width: 100, height: 50))
                XCTAssertEqual(blueprintView.sizeThatFits(CGSize(width: 100.0, height: CGFloat.greatestFiniteMagnitude)), CGSize(width: 100, height: 50))
                XCTAssertEqual(blueprintView.sizeThatFits(CGSize(width: 100.0, height: CGFloat.infinity)), CGSize(width: 100, height: 50))
            }
        }
    }

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
    
    func test_nil_element() {
        
        let view = BlueprintView()
        view.layoutIfNeeded()
        
        XCTAssertNil(view.element)
        XCTAssertEqual(view.needsViewHierarchyUpdate, false)
        
        view.element = nil
        XCTAssertEqual(view.needsViewHierarchyUpdate, false)
    }

    func test_recursiveLayout() {
        let view = BlueprintView()

        var layoutRecursed = false

        func onLayoutSubviews() {
            layoutRecursed = true
        }

        struct TestElement: Element {
            var onLayoutSubviews: () -> Void

            var content: ElementContent {
                ElementContent(intrinsicSize: .zero)
            }

            func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
                TestView.describe { (config) in
                    config.apply { (view) in
                        // make sure UIKit knows we want a chance for layout
                        view.setNeedsLayout()
                    }
                    config[\.onLayoutSubviews] = self.onLayoutSubviews
                }
            }

            class TestView: UIView {
                var onLayoutSubviews: (() -> Void)?

                override func layoutSubviews() {
                    super.layoutSubviews()
                    onLayoutSubviews?()
                }
            }
        }

        view.element = TestElement(onLayoutSubviews: onLayoutSubviews)

        // trigger a layout pass
        _ = view.currentNativeViewControllers

        XCTAssertTrue(layoutRecursed)
    }
}

fileprivate struct MeasurableElement : Element {
        
    var validate : (SizeConstraint) -> CGSize
    
    var content: ElementContent {
        ElementContent { constraint -> CGSize in
            self.validate(constraint)
        }
    }
    
    func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return nil
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
        return ElementContent(layout: TestLayout()) { (builder) in
            for child in children {
                builder.add(element: child)
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
