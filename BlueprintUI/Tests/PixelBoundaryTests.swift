import XCTest
@testable import BlueprintUI

class PixelBoundaryTests: XCTestCase {
    func test_rounding3scale1() {
        let frame = CGRect(origin: .zero, size: CGSize(width: 100, height: 100))
        let element = elementTree(shiftedBy: 0.3, depth: 3)

        let layoutResultNode = element.layout(frame: frame)

        var rootNode = NativeViewNode(
            content: UIView.describe { _ in },
            environment: .empty,
            layoutAttributes: LayoutAttributes(frame: frame),
            children: layoutResultNode.resolve()
        )

        let unroundedFrames = globalFrames(in: rootNode)
        assert(rect: unroundedFrames[0], closeTo: CGRect(minX: 0.0, minY: 0.0, maxX: 100, maxY: 100))
        assert(rect: unroundedFrames[1], closeTo: CGRect(minX: 0.3, minY: 0.3, maxX: 99.7, maxY: 99.7))
        assert(rect: unroundedFrames[2], closeTo: CGRect(minX: 0.6, minY: 0.6, maxX: 99.4, maxY: 99.4))
        assert(rect: unroundedFrames[3], closeTo: CGRect(minX: 0.9, minY: 0.9, maxX: 99.1, maxY: 99.1))

        rootNode.round(from: .zero, correction: .zero, scale: 1.0)

        let roundedFrames = globalFrames(in: rootNode)
        assert(rect: roundedFrames[0], closeTo: CGRect(minX: 0.0, minY: 0.0, maxX: 100, maxY: 100))
        assert(rect: roundedFrames[1], closeTo: CGRect(minX: 0.0, minY: 0.0, maxX: 100, maxY: 100))
        assert(rect: roundedFrames[2], closeTo: CGRect(minX: 1.0, minY: 1.0, maxX: 99.0, maxY: 99.0))
        assert(rect: roundedFrames[3], closeTo: CGRect(minX: 1.0, minY: 1.0, maxX: 99.0, maxY: 99.0))
    }

    func test_rounding3scale2() {
        let frame = CGRect(origin: .zero, size: CGSize(width: 100, height: 100))
        let element = elementTree(shiftedBy: 0.3, depth: 3)

        let layoutResultNode = element.layout(frame: frame)

        var rootNode = NativeViewNode(
            content: UIView.describe { _ in },
            environment: .empty,
            layoutAttributes: LayoutAttributes(frame: frame),
            children: layoutResultNode.resolve()
        )

        let unroundedFrames = globalFrames(in: rootNode)
        assert(rect: unroundedFrames[0], closeTo: CGRect(minX: 0.0, minY: 0.0, maxX: 100, maxY: 100))
        assert(rect: unroundedFrames[1], closeTo: CGRect(minX: 0.3, minY: 0.3, maxX: 99.7, maxY: 99.7))
        assert(rect: unroundedFrames[2], closeTo: CGRect(minX: 0.6, minY: 0.6, maxX: 99.4, maxY: 99.4))
        assert(rect: unroundedFrames[3], closeTo: CGRect(minX: 0.9, minY: 0.9, maxX: 99.1, maxY: 99.1))

        rootNode.round(from: .zero, correction: .zero, scale: 2.0)

        let roundedFrames = globalFrames(in: rootNode)
        assert(rect: roundedFrames[0], closeTo: CGRect(minX: 0.0, minY: 0.0, maxX: 100, maxY: 100))
        assert(rect: roundedFrames[1], closeTo: CGRect(minX: 0.5, minY: 0.5, maxX: 99.5, maxY: 99.5))
        assert(rect: roundedFrames[2], closeTo: CGRect(minX: 0.5, minY: 0.5, maxX: 99.5, maxY: 99.5))
        assert(rect: roundedFrames[3], closeTo: CGRect(minX: 1.0, minY: 1.0, maxX: 99.0, maxY: 99.0))
    }

    func test_rounding5scale1() {
        let frame = CGRect(origin: .zero, size: CGSize(width: 100, height: 100))
        let element = elementTree(shiftedBy: 0.5, depth: 3)

        let layoutResultNode = element.layout(frame: frame)

        var rootNode = NativeViewNode(
            content: UIView.describe { _ in },
            environment: .empty,
            layoutAttributes: LayoutAttributes(frame: frame),
            children: layoutResultNode.resolve()
        )

        let unroundedFrames = globalFrames(in: rootNode)
        assert(rect: unroundedFrames[0], closeTo: CGRect(minX: 0.0, minY: 0.0, maxX: 100, maxY: 100))
        assert(rect: unroundedFrames[1], closeTo: CGRect(minX: 0.5, minY: 0.5, maxX: 99.5, maxY: 99.5))
        assert(rect: unroundedFrames[2], closeTo: CGRect(minX: 1.0, minY: 1.0, maxX: 99.0, maxY: 99.0))
        assert(rect: unroundedFrames[3], closeTo: CGRect(minX: 1.5, minY: 1.5, maxX: 98.5, maxY: 98.5))

        rootNode.round(from: .zero, correction: .zero, scale: 1.0)

        let roundedFrames = globalFrames(in: rootNode)
        assert(rect: roundedFrames[0], closeTo: CGRect(minX: 0.0, minY: 0.0, maxX: 100, maxY: 100))
        assert(rect: roundedFrames[1], closeTo: CGRect(minX: 1.0, minY: 1.0, maxX: 100, maxY: 100))
        assert(rect: roundedFrames[2], closeTo: CGRect(minX: 1.0, minY: 1.0, maxX: 99.0, maxY: 99.0))
        assert(rect: roundedFrames[3], closeTo: CGRect(minX: 2.0, minY: 2.0, maxX: 99.0, maxY: 99.0))
    }

    func test_rounding9scale1() {
        let frame = CGRect(origin: .zero, size: CGSize(width: 100, height: 100))
        let element = elementTree(shiftedBy: 0.9, depth: 3)

        let layoutResultNode = element.layout(frame: frame)

        var rootNode = NativeViewNode(
            content: UIView.describe { _ in },
            environment: .empty,
            layoutAttributes: LayoutAttributes(frame: frame),
            children: layoutResultNode.resolve()
        )

        let unroundedFrames = globalFrames(in: rootNode)
        assert(rect: unroundedFrames[0], closeTo: CGRect(minX: 0.0, minY: 0.0, maxX: 100, maxY: 100))
        assert(rect: unroundedFrames[1], closeTo: CGRect(minX: 0.9, minY: 0.9, maxX: 99.1, maxY: 99.1))
        assert(rect: unroundedFrames[2], closeTo: CGRect(minX: 1.8, minY: 1.8, maxX: 98.2, maxY: 98.2))
        assert(rect: unroundedFrames[3], closeTo: CGRect(minX: 2.7, minY: 2.7, maxX: 97.3, maxY: 97.3))

        rootNode.round(from: .zero, correction: .zero, scale: 1.0)

        let roundedFrames = globalFrames(in: rootNode)
        assert(rect: roundedFrames[0], closeTo: CGRect(minX: 0.0, minY: 0.0, maxX: 100, maxY: 100))
        assert(rect: roundedFrames[1], closeTo: CGRect(minX: 1.0, minY: 1.0, maxX: 99.0, maxY: 99.0))
        assert(rect: roundedFrames[2], closeTo: CGRect(minX: 2.0, minY: 2.0, maxX: 98.0, maxY: 98.0))
        assert(rect: roundedFrames[3], closeTo: CGRect(minX: 3.0, minY: 3.0, maxX: 97.0, maxY: 97.0))
    }

    func test_roundingNegative() {
        let frame = CGRect(origin: .zero, size: CGSize(width: 100, height: 100))
        let element = elementTree(shiftedBy: -1.5, depth: 3)

        let layoutResultNode = element.layout(frame: frame)

        var rootNode = NativeViewNode(
            content: UIView.describe { _ in },
            environment: .empty,
            layoutAttributes: LayoutAttributes(frame: frame),
            children: layoutResultNode.resolve()
        )

        let unroundedFrames = globalFrames(in: rootNode)
        assert(rect: unroundedFrames[0], closeTo: CGRect(minX: 0.0, minY: 0.0, maxX: 100, maxY: 100))
        assert(rect: unroundedFrames[1], closeTo: CGRect(minX: -1.5, minY: -1.5, maxX: 101.5, maxY: 101.5))
        assert(rect: unroundedFrames[2], closeTo: CGRect(minX: -3.0, minY: -3.0, maxX: 103.0, maxY: 103.0))
        assert(rect: unroundedFrames[3], closeTo: CGRect(minX: -4.5, minY: -4.5, maxX: 104.5, maxY: 104.5))

        rootNode.round(from: .zero, correction: .zero, scale: 1.0)

        let roundedFrames = globalFrames(in: rootNode)
        assert(rect: roundedFrames[0], closeTo: CGRect(minX: 0.0, minY: 0.0, maxX: 100, maxY: 100))
        assert(rect: roundedFrames[1], closeTo: CGRect(minX: -2.0, minY: -2.0, maxX: 102.0, maxY: 102.0))
        assert(rect: roundedFrames[2], closeTo: CGRect(minX: -3.0, minY: -3.0, maxX: 103.0, maxY: 103.0))
        assert(rect: roundedFrames[3], closeTo: CGRect(minX: -5.0, minY: -5.0, maxX: 105.0, maxY: 105.0))
    }

    /// Walk a node tree down each node's first child and return an array of their frames, in global coordinates.
    func globalFrames(in node: NativeViewNode, origin: CGPoint = .zero) -> [CGRect] {
        guard let child = node.children.first?.node else {
            return []
        }

        let localFrame = node.layoutAttributes.frame
        let globalFrame = CGRect(
            minX: origin.x + localFrame.minX,
            minY: origin.y + localFrame.minY,
            maxX: origin.x + localFrame.maxX,
            maxY: origin.y + localFrame.maxY
        )

        let origin = origin + node.layoutAttributes.frame.origin

        return [globalFrame] + globalFrames(in: child, origin: origin)
    }

    func assert(rect rect1: CGRect, closeTo rect2: CGRect, file: StaticString = #file, line: UInt = #line) {
        let accuracy: CGFloat = .ulpOfOne * 64.0
        XCTAssertEqual(rect1.minY, rect2.minY, accuracy: accuracy, file: file, line: line)
        XCTAssertEqual(rect1.minX, rect2.minX, accuracy: accuracy, file: file, line: line)
        XCTAssertEqual(rect1.maxY, rect2.maxY, accuracy: accuracy, file: file, line: line)
        XCTAssertEqual(rect1.maxX, rect2.maxX, accuracy: accuracy, file: file, line: line)
    }

    /// Generate a tree of view-backed elements with insets
    func elementTree(shiftedBy inset: CGFloat, depth: Int) -> Element {
        guard depth > 0 else {
            return Container(wrapping: nil)
        }

        return Inset(
            uniformInset: inset,
            wrapping: Container(
                wrapping: elementTree(shiftedBy: inset, depth: depth - 1))
        )
    }

    /// A view-backed box to generate a native view node
    struct Container: Element {
        var wrappedElement: Element?

        init(wrapping: Element?) {
            wrappedElement = wrapping
        }

        var content: ElementContent {
            if let wrappedElement = wrappedElement {
                return ElementContent(child: wrappedElement)
            } else {
                return ElementContent(intrinsicSize: .zero)
            }
        }

        func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
            UIView.describe { _ in }
        }
    }
}
