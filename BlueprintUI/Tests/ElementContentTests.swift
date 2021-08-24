import XCTest
@testable import BlueprintUI

class ElementContentTests: XCTestCase {

    func test_measurement_caching() {

        let environment = Environment.empty

        let element = MeasurableElement()

        _ = element.content.measure(in: .unconstrained, environment: environment)
        XCTAssertEqual(MeasurableElement.measureCount, 1)

        _ = element.content.measure(in: .unconstrained, environment: environment)
        XCTAssertEqual(MeasurableElement.measureCount, 1)

        _ = element.content.measure(in: .unconstrained, environment: environment)
        XCTAssertEqual(MeasurableElement.measureCount, 1)
    }

    func test_noChildren() {
        let container = ElementContent(layout: FrameLayout())
        XCTAssertEqual(container.childCount, 0)
        XCTAssertEqual(
            container.measure(in: SizeConstraint(CGSize(width: 100, height: 100)), environment: .empty),
            CGSize.zero
        )
    }

    func test_singleChild() {
        let frame = CGRect(x: 0, y: 0, width: 20, height: 20)

        let container = ElementContent(layout: FrameLayout()) {
            $0.add(traits: frame, element: SimpleElement())
        }

        let children = container
            .testLayout(attributes: LayoutAttributes(frame: .zero))
            .map { $0.node }

        XCTAssertEqual(children.count, 1)

        XCTAssertEqual(children[0].layoutAttributes, LayoutAttributes(frame: frame))

        XCTAssertEqual(
            container.measure(in: SizeConstraint(CGSize.zero), environment: .empty),
            CGSize(width: frame.maxX, height: frame.maxY)
        )
    }

    func test_multipleChildren() {

        let frame1 = CGRect(x: 0, y: 0, width: 20, height: 20)
        let frame2 = CGRect(x: 200, y: 300, width: 400, height: 500)

        let container = ElementContent(layout: FrameLayout()) {
            $0.add(traits: frame1, element: SimpleElement())
            $0.add(traits: frame2, element: SimpleElement())
        }

        let children = container
            .testLayout(attributes: LayoutAttributes(frame: .zero))
            .map { $0.node }

        XCTAssertEqual(children.count, 2)

        XCTAssertEqual(children[0].layoutAttributes, LayoutAttributes(frame: frame1))
        XCTAssertEqual(children[1].layoutAttributes, LayoutAttributes(frame: frame2))

        XCTAssertEqual(
            container.measure(in: SizeConstraint(CGSize.zero), environment: .empty),
            CGSize(width: 600, height: 800)
        )
    }

    func test_cacheTree() {
        let size1 = CGSize(width: 10, height: 15)
        let size2 = CGSize(width: 20, height: 25)

        let containerSize = CGSize(width: 600, height: 800)
        let halfSize = CGSize(width: 300, height: 400)

        func layout(sizes: [CGSize]) -> (TestCache, TestCounter) {
            let counts = TestCounter()
            let layout = MeasureCountingLayout(counts: counts, layout: HalfLayout())

            let container = ElementContent(layout: layout) { builder in
                for size in sizes {
                    builder.add(element: MeasureCountingSpacer(size: size, counts: counts))
                }
            }
            let cache = TestCache(name: "test")

            _ = container
                .performLayout(
                    attributes: LayoutAttributes(size: containerSize),
                    environment: .empty,
                    cache: cache
                )
                .map { $0.node }

            _ = container.measure(
                in: SizeConstraint(containerSize),
                environment: .empty,
                cache: cache
            )

            return (cache, counts)
        }

        // Multiple children
        do {
            let (cache, counts) = layout(sizes: [size1, size2])

            XCTAssertEqual(
                cache.measurements,
                [SizeConstraint(containerSize): CGSize(width: 30, height: 40)]
            )

            XCTAssertEqual(cache.subcaches.count, 2)
            XCTAssertEqual(
                cache.subcaches[0]!.measurements,
                [SizeConstraint(halfSize): size1]
            )
            XCTAssertEqual(
                cache.subcaches[1]!.measurements,
                [SizeConstraint(halfSize): size2]
            )

            XCTAssertTrue(cache.subcaches[0]!.subcaches.isEmpty)
            XCTAssertTrue(cache.subcaches[1]!.subcaches.isEmpty)

            XCTAssertEqual(counts.measures, 3)
        }

        // Single child
        do {
            let (cache, counts) = layout(sizes: [size1])

            XCTAssertEqual(
                cache.measurements,
                [SizeConstraint(containerSize): size1]
            )

            XCTAssertEqual(cache.subcaches.count, 1)
            XCTAssertEqual(
                cache.subcaches[0]!.measurements,
                [SizeConstraint(halfSize): size1]
            )

            XCTAssertTrue(cache.subcaches[0]!.subcaches.isEmpty)

            XCTAssertEqual(counts.measures, 2)
        }
    }

    func test_roundingElementSize() {
        // These values are based on actual numbers that measuring UILabel has returned

        let row = Row {
            $0.add(child: SizedElement(size: CGSize(width: 0.33333333333334, height: 1)))
            $0.add(child: SizedElement(size: CGSize(width: 0.66666666666669, height: 1)))
        }

        let inset = row.inset(uniform: 24)

        let rowSize = row.content.measure(in: .unconstrained)
        let insetSize = inset.content.measure(in: .unconstrained)

        // The measured row width should equal the measured inset width with the insets subtracted
        XCTAssertEqual(insetSize.width - inset.left - inset.right, rowSize.width)

        // The measured row should be rounded to the nearest pixel
        XCTAssertEqual(rowSize.width, 1)
    }
}

fileprivate struct MeasurableElement: Element {

    static var measureCount: Int = 0

    var content: ElementContent {
        ElementContent(measurementCachingKey: .init(type: Self.self, input: "element")) { constraint -> CGSize in
            Self.measureCount += 1
            return .init(width: 20.0, height: 20.0)
        }
    }

    func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        UIView.describe { _ in }
    }
}

fileprivate struct SimpleElement: Element {

    var content: ElementContent {
        return ElementContent(intrinsicSize: .zero)
    }

    func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        return nil
    }

}

fileprivate struct SizedElement: Element {

    var size: CGSize

    var content: ElementContent {
        return ElementContent(intrinsicSize: size)
    }

    func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        nil
    }
}

fileprivate struct FrameLayout: Layout {

    typealias Traits = CGRect

    func measure(in constraint: SizeConstraint, items: [(traits: CGRect, content: Measurable)]) -> CGSize {
        return items.reduce(into: CGSize.zero) { result, item in
            result.width = max(result.width, item.traits.maxX)
            result.height = max(result.height, item.traits.maxY)
        }
    }

    func layout(size: CGSize, items: [(traits: CGRect, content: Measurable)]) -> [LayoutAttributes] {
        return items.map { LayoutAttributes(frame: $0.traits) }
    }

    static var defaultTraits: CGRect {
        return CGRect.zero
    }

}

private struct HalfLayout: Layout {
    func measure(in constraint: SizeConstraint, items: [(traits: (), content: Measurable)]) -> CGSize {
        let halfConstraint = SizeConstraint(
            width: constraint.width / 2,
            height: constraint.height / 2
        )
        let measurements = items.map { $1.measure(in: halfConstraint) }
        return CGSize(
            width: measurements.map(\.width).reduce(0, +),
            height: measurements.map(\.height).reduce(0, +)
        )
    }

    func layout(size: CGSize, items: [(traits: (), content: Measurable)]) -> [LayoutAttributes] {
        let halfConstraint = SizeConstraint(CGSize(width: size.width / 2, height: size.height / 2))
        return items.map {
            LayoutAttributes(size: $1.measure(in: halfConstraint))
        }
    }
}

private class TestCounter {
    var measures: Int = 0
}

private struct MeasureCountingLayout<WrappedLayout>: Layout where WrappedLayout: Layout {
    static var defaultTraits: Traits { WrappedLayout.defaultTraits }

    typealias Traits = WrappedLayout.Traits

    var counts: TestCounter
    var layout: WrappedLayout

    func measure(in constraint: SizeConstraint, items: [(traits: Traits, content: Measurable)]) -> CGSize {
        counts.measures += 1
        return layout.measure(in: constraint, items: items)
    }

    func layout(size: CGSize, items: [(traits: Traits, content: Measurable)]) -> [LayoutAttributes] {
        return layout.layout(size: size, items: items)
    }
}

private struct MeasureCountingSpacer: Element {
    var size: CGSize
    var counts: TestCounter

    var content: ElementContent {
        ElementContent(
            layout: MeasureCountingLayout(counts: counts, layout: FixedLayout(size: size))
        )
    }

    func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        nil
    }

    struct FixedLayout: Layout {
        var size: CGSize

        func measure(in constraint: SizeConstraint, items: [(traits: (), content: Measurable)]) -> CGSize {
            size
        }

        func layout(size: CGSize, items: [(traits: (), content: Measurable)]) -> [LayoutAttributes] {
            []
        }
    }
}

private class TestCache: CacheTree {
    var name: String
    var signpostRef: AnyObject { self }

    var measurements: [SizeConstraint: CGSize] = [:]
    var subcaches: [SubcacheKey: TestCache] = [:]

    init(name: String) {
        self.name = name
    }

    subscript(constraint: SizeConstraint) -> CGSize? {
        get { measurements[constraint] }
        set { measurements[constraint] = newValue }
    }

    func subcache(key: SubcacheKey, name: @autoclosure () -> String) -> CacheTree {
        if let subcache = subcaches[key] {
            return subcache
        }
        let subcache = TestCache(name: "\(self.name).\(name())")
        subcaches[key] = subcache
        return subcache
    }

}

