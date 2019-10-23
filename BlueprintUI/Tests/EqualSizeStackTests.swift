import XCTest
@testable import BlueprintUI

class EqualSizeStackTests: XCTestCase {

    func test_defaults() {
        let stack = EqualSizeStack(direction: .horizontal)
        XCTAssertEqual(stack.gutter, 0)
        XCTAssertTrue(stack.children.isEmpty)
    }

    func test_measuring() {

        let children = [
            TestElement(size: CGSize(width: 50, height: 50)),
            TestElement(size: CGSize(width: 100, height: 100)),
            TestElement(size: CGSize(width: 150, height: 150))
        ]

        let constraint = SizeConstraint.unconstrained

        // direction = .horizontal, gutter = 0
        do {
            let stack = EqualSizeStack(
                direction: .horizontal,
                gutter: 0,
                children: children)

            XCTAssertEqual(stack.content.measure(in: constraint), CGSize(width: 300, height: 150))
        }

        // direction = .horizontal, gutter = 50
        do {
            let stack = EqualSizeStack(
                direction: .horizontal,
                gutter: 50,
                children: children)

            XCTAssertEqual(stack.content.measure(in: constraint), CGSize(width: 400, height: 150))
        }

        // direction = .vertical, gutter = 0
        do {
            let stack = EqualSizeStack(
                direction: .vertical,
                gutter: 0,
                children: children)

            XCTAssertEqual(stack.content.measure(in: constraint), CGSize(width: 150, height: 300))
        }

        // direction = .vertical, gutter = 50
        do {
            let stack = EqualSizeStack(
                direction: .vertical,
                gutter: 50,
                children: children)

            XCTAssertEqual(stack.content.measure(in: constraint), CGSize(width: 150, height: 400))
        }

    }

    func test_layout() {

        let children = [
            TestElement(size: CGSize(width: 50, height: 50)),
            TestElement(size: CGSize(width: 100, height: 100)),
            TestElement(size: CGSize(width: 150, height: 150))
        ]

        // direction = .horizontal, gutter = 0
        do {
            let stack = EqualSizeStack(
                direction: .horizontal,
                gutter: 0,
                children: children)

            let childFrames = stack
                .layout(frame: CGRect(x: 0, y: 0, width: 150, height: 150))
                .children
                .map { $0.node.layoutAttributes.frame }

            XCTAssertEqual(childFrames, [
                CGRect(x: 0, y: 0, width: 50, height: 150),
                CGRect(x: 50, y: 0, width: 50, height: 150),
                CGRect(x: 100, y: 0, width: 50, height: 150)
            ])
        }

        // direction = .horizontal, gutter = 50
        do {
            let stack = EqualSizeStack(
                direction: .horizontal,
                gutter: 50,
                children: children)

            let childFrames = stack
                .layout(frame: CGRect(x: 0, y: 0, width: 700, height: 700))
                .children
                .map { $0.node.layoutAttributes.frame }

            XCTAssertEqual(childFrames, [
                CGRect(x: 0, y: 0, width: 200, height: 700),
                CGRect(x: 250, y: 0, width: 200, height: 700),
                CGRect(x: 500, y: 0, width: 200, height: 700)
            ])
        }

        // direction = .vertical, gutter = 0
        do {
            let stack = EqualSizeStack(
                direction: .vertical,
                gutter: 0,
                children: children)

            let childFrames = stack
                .layout(frame: CGRect(x: 0, y: 0, width: 600, height: 600))
                .children
                .map { $0.node.layoutAttributes.frame }

            XCTAssertEqual(childFrames, [
                CGRect(x: 0, y: 0, width: 600, height: 200),
                CGRect(x: 0, y: 200, width: 600, height: 200),
                CGRect(x: 0, y: 400, width: 600, height: 200)
            ])
        }

        // direction = .vertical, gutter = 25
        do {
            let stack = EqualSizeStack(
                direction: .vertical,
                gutter: 25,
                children: children)

            let childFrames = stack
                .layout(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
                .children
                .map { $0.node.layoutAttributes.frame }

            XCTAssertEqual(childFrames, [
                CGRect(x: 0, y: 0, width: 200, height: 50),
                CGRect(x: 0, y: 75, width: 200, height: 50),
                CGRect(x: 0, y: 150, width: 200, height: 50)
            ])
        }

    }

}



fileprivate struct TestElement: Element {

    var size: CGSize

    init(size: CGSize = CGSize(width: 100, height: 100)) {
        self.size = size
    }

    var content: ElementContent {
        return ElementContent(intrinsicSize: size)
    }

    func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return nil
    }

}
