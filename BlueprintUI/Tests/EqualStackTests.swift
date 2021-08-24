import XCTest
@testable import BlueprintUI

class EqualStackTests: XCTestCase {

    func test_defaults() {
        let stack = EqualStack(direction: .horizontal)
        XCTAssertEqual(stack.spacing, 0)
        XCTAssertTrue(stack.children.isEmpty)
    }

    func test_measuring_unconstrained() {

        let children = [
            TestElement(size: CGSize(width: 50, height: 50)),
            TestElement(size: CGSize(width: 100, height: 100)),
            TestElement(size: CGSize(width: 150, height: 150)),
        ]

        let constraint = SizeConstraint.unconstrained

        // direction = .horizontal, spacing = 0
        do {
            let stack = EqualStack(direction: .horizontal) { stack in
                stack.spacing = 0
                stack.children = children
            }

            XCTAssertEqual(stack.content.measure(in: constraint), CGSize(width: 450, height: 150))
        }

        // direction = .horizontal, spacing = 50
        do {
            let stack = EqualStack(direction: .horizontal) { stack in
                stack.spacing = 50
                stack.children = children
            }

            XCTAssertEqual(stack.content.measure(in: constraint), CGSize(width: 550, height: 150))
        }

        // direction = .vertical, spacing = 0
        do {
            let stack = EqualStack(direction: .vertical) { stack in
                stack.spacing = 0
                stack.children = children
            }

            XCTAssertEqual(stack.content.measure(in: constraint), CGSize(width: 150, height: 450))
        }

        // direction = .vertical, spacing = 50
        do {
            let stack = EqualStack(direction: .vertical) { stack in
                stack.spacing = 50
                stack.children = children
            }

            XCTAssertEqual(stack.content.measure(in: constraint), CGSize(width: 150, height: 550))
        }

    }

    func test_measuring_constrained() {

        let children = [
            AreaElement(area: 100),
            AreaElement(area: 1200), // The only one affecting the cross-axis size
            AreaElement(area: 100),
        ]

        // direction = .horizontal
        do {
            let constraint = SizeConstraint(width: .atMost(300), height: .unconstrained)

            // spacing = 0
            do {
                let stack = EqualStack(direction: .horizontal) { stack in
                    stack.spacing = 0
                    stack.children = children
                }

                // 300 / 3 = 100
                // 1200 / 100 = 12
                XCTAssertEqual(stack.content.measure(in: constraint), CGSize(width: 300, height: 12))
            }

            // spacing = 30
            do {
                let stack = EqualStack(direction: .horizontal) { stack in
                    stack.spacing = 30
                    stack.children = children
                }

                // 300 - 30 - 30 = 240
                // 240 / 3 = 80
                // 1200 / 80 = 15
                XCTAssertEqual(stack.content.measure(in: constraint), CGSize(width: 300, height: 15))
            }
        }

        // direction = .vertical
        do {
            let constraint = SizeConstraint(width: .unconstrained, height: .atMost(400))

            // spacing = 0
            do {
                let stack = EqualStack(direction: .vertical) { stack in
                    stack.spacing = 0
                    stack.children = children
                }

                // 400 / 3 = 133.333, rounded up to 133.5…
                // 1200 / 133.333… = 9
                XCTAssertEqual(stack.content.measure(in: constraint), CGSize(width: 9, height: 400.5))
            }

            // spacing = 50
            do {
                let stack = EqualStack(direction: .vertical) { stack in
                    stack.spacing = 50
                    stack.children = children
                }

                // 400 - 50 - 50 = 300
                // 300 / 3 = 100
                // 1200 / 100 = 12
                XCTAssertEqual(stack.content.measure(in: constraint), CGSize(width: 12, height: 400))

            }
        }

    }

    func test_layout() {

        let children = [
            TestElement(size: CGSize(width: 50, height: 50)),
            TestElement(size: CGSize(width: 100, height: 100)),
            TestElement(size: CGSize(width: 150, height: 150)),
        ]

        // direction = .horizontal, spacing = 0
        do {
            let stack = EqualStack(direction: .horizontal) { stack in
                stack.spacing = 0
                stack.children = children
            }

            let childFrames = stack
                .layout(frame: CGRect(x: 0, y: 0, width: 150, height: 150))
                .children
                .map { $0.node.layoutAttributes.frame }

            XCTAssertEqual(childFrames, [
                CGRect(x: 0, y: 0, width: 50, height: 150),
                CGRect(x: 50, y: 0, width: 50, height: 150),
                CGRect(x: 100, y: 0, width: 50, height: 150),
            ])
        }

        // direction = .horizontal, spacing = 50
        do {
            let stack = EqualStack(direction: .horizontal) { stack in
                stack.spacing = 50
                stack.children = children
            }

            let childFrames = stack
                .layout(frame: CGRect(x: 0, y: 0, width: 700, height: 700))
                .children
                .map { $0.node.layoutAttributes.frame }

            XCTAssertEqual(childFrames, [
                CGRect(x: 0, y: 0, width: 200, height: 700),
                CGRect(x: 250, y: 0, width: 200, height: 700),
                CGRect(x: 500, y: 0, width: 200, height: 700),
            ])
        }

        // direction = .vertical, spacing = 0
        do {
            let stack = EqualStack(direction: .vertical) { stack in
                stack.spacing = 0
                stack.children = children
            }

            let childFrames = stack
                .layout(frame: CGRect(x: 0, y: 0, width: 600, height: 600))
                .children
                .map { $0.node.layoutAttributes.frame }

            XCTAssertEqual(childFrames, [
                CGRect(x: 0, y: 0, width: 600, height: 200),
                CGRect(x: 0, y: 200, width: 600, height: 200),
                CGRect(x: 0, y: 400, width: 600, height: 200),
            ])
        }

        // direction = .vertical, spacing = 25
        do {
            let stack = EqualStack(direction: .vertical) { stack in
                stack.spacing = 25
                stack.children = children
            }

            let childFrames = stack
                .layout(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
                .children
                .map { $0.node.layoutAttributes.frame }

            XCTAssertEqual(childFrames, [
                CGRect(x: 0, y: 0, width: 200, height: 50),
                CGRect(x: 0, y: 75, width: 200, height: 50),
                CGRect(x: 0, y: 150, width: 200, height: 50),
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

    func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        return nil
    }

}

/// Test element that will measure itself to take up the given area in points
fileprivate struct AreaElement: Element {

    var area: CGFloat

    init(area: CGFloat = 25) {
        self.area = area
    }

    var content: ElementContent {
        return ElementContent { [area] constraint in
            if case .atMost(let maxWidth) = constraint.width {
                return CGSize(
                    width: maxWidth,
                    height: area / maxWidth
                )
            } else if case .atMost(let maxHeight) = constraint.height {
                return CGSize(
                    width: area / maxHeight,
                    height: maxHeight
                )
            } else {
                return CGSize(
                    width: area.squareRoot(),
                    height: area.squareRoot()
                )
            }
        }
    }

    func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        return nil
    }

}
