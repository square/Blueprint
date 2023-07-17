import XCTest
@testable import BlueprintUI

class ElementContentTests: XCTestCase {

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

    func test_measureFunction() {
        let expectedConstraint = SizeConstraint(width: .atMost(100), height: .atMost(200))
        let expectedSafeArea = UIEdgeInsets(top: 1, left: 2, bottom: 3, right: 4)

        let content = ElementContent { constraint, env -> CGSize in
            XCTAssertEqual(constraint, expectedConstraint)
            XCTAssertEqual(env.safeAreaInsets, expectedSafeArea)

            return CGSize(width: 10, height: 20)
        }

        var env = Environment.empty
        env.safeAreaInsets = UIEdgeInsets(top: 1, left: 2, bottom: 3, right: 4)

        let size = content.measure(in: expectedConstraint, environment: env)

        XCTAssertEqual(size, CGSize(width: 10, height: 20))
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
                .performLegacyLayout(
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

    func test_layout_phase() {

        var callCount: Int = 0

        let measure = ElementContent { phase, size, env in
            XCTAssertEqual(phase, .measurement)
            callCount += 1

            return Empty()
        }

        let layout = ElementContent { phase, size, env in
            XCTAssertEqual(phase, .layout)
            callCount += 1

            return Empty()
        }

        let size = measure.measure(in: .unconstrained)

        _ = layout.performLegacyLayout(
            attributes: .init(size: size),
            environment: .empty,
            cache: TestCache(name: "test")
        )

        XCTAssertEqual(callCount, 2)
    }

    func test_measuring() {

        struct InnerTestElement: Element {

            var measure: (SizeConstraint) -> CGSize

            var content: ElementContent {
                ElementContent(measureFunction: measure)
            }

            func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
                nil
            }
        }

        struct OuterTestElement: Element {

            var element: InnerTestElement

            var content: ElementContent {
                ElementContent(measuring: element)
            }

            func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
                nil
            }
        }

        var calls: [SizeConstraint] = []

        let element = OuterTestElement(
            element: InnerTestElement { constraint in
                calls.append(constraint)
                return CGSize(width: 100, height: 10)
            }
        )

        let cache = RenderPassCache(name: "Test", signpostRef: NSObject())

        /// Should output the size of the inner element.

        XCTAssertEqual(
            CGSize(width: 100, height: 10),
            element.content.measure(in: .init(CGSize(width: 100, height: 100)), environment: .empty, cache: cache)
        )

        let layoutResult = element.layout(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 100)))

        XCTAssertTrue(layoutResult.children.isEmpty)
    }
}

fileprivate struct MeasurableElement: Element {

    var content: ElementContent {
        ElementContent { constraint -> CGSize in
            .init(width: 20.0, height: 20.0)
        }
    }

    func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        UIView.describe { _ in }
    }
}

fileprivate struct SimpleElement: Element {

    var content: ElementContent {
        ElementContent(intrinsicSize: .zero)
    }

    func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        nil
    }

}


fileprivate struct FrameLayout: Layout {

    typealias Traits = CGRect

    func measure(in constraint: SizeConstraint, items: [(traits: CGRect, content: Measurable)]) -> CGSize {
        items.reduce(into: CGSize.zero) { result, item in
            result.width = max(result.width, item.traits.maxX)
            result.height = max(result.height, item.traits.maxY)
        }
    }

    func layout(size: CGSize, items: [(traits: CGRect, content: Measurable)]) -> [LayoutAttributes] {
        items.map { LayoutAttributes(frame: $0.traits) }
    }

    func sizeThatFits(
        proposal: SizeConstraint,
        subelements: Subelements,
        environment: Environment,
        cache: inout ()
    ) -> CGSize {
        subelements.reduce(into: CGSize.zero) { result, subview in
            let traits = subview.traits(forLayoutType: FrameLayout.self)
            result.width = max(result.width, traits.maxX)
            result.height = max(result.height, traits.maxY)
        }
    }

    func placeSubelements(
        in size: CGSize,
        subelements: Subelements,
        environment: Environment,
        cache: inout ()
    ) {
        for subelement in subelements {
            let frame = subelement.traits(forLayoutType: FrameLayout.self)
            subelement.place(
                at: frame.origin,
                size: frame.size
            )
        }
    }

    static var defaultTraits: CGRect {
        CGRect.zero
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

    func sizeThatFits(
        proposal: SizeConstraint,
        subelements: Subelements,
        environment: Environment,
        cache: inout ()
    ) -> CGSize {
        fatalError("Not supported in Caffeinated Layout")
    }

    func placeSubelements(
        in size: CGSize,
        subelements: Subelements,
        environment: Environment,
        cache: inout ()
    ) {
        fatalError("Not supported in Caffeinated Layout")
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
        layout.layout(size: size, items: items)
    }

    func sizeThatFits(
        proposal: SizeConstraint,
        subelements: Subelements,
        environment: Environment,
        cache: inout WrappedLayout.Cache
    ) -> CGSize {
        counts.measures += 1
        return layout.sizeThatFits(
            proposal: proposal,
            subelements: subelements,
            environment: environment,
            cache: &cache
        )
    }

    func placeSubelements(
        in size: CGSize,
        subelements: Subelements,
        environment: Environment,
        cache: inout WrappedLayout.Cache
    ) {
        layout.placeSubelements(
            in: size,
            subelements: subelements,
            environment: environment,
            cache: &cache
        )
    }

    func makeCache(subelements: Subelements, environment: Environment) -> WrappedLayout.Cache {
        layout.makeCache(subelements: subelements, environment: environment)
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

        func sizeThatFits(
            proposal: SizeConstraint,
            subelements: Subelements,
            environment: Environment,
            cache: inout ()
        ) -> CGSize {
            size
        }

        func placeSubelements(
            in size: CGSize,
            subelements: Subelements,
            environment: Environment,
            cache: inout ()
        ) {
            // No-op
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
