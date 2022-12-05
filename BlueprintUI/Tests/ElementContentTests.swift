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
            .testLayout(in: .zero)

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
            .testLayout(in: .zero)

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

        _ = layout.testLayout(in: size)

        XCTAssertEqual(callCount, 2)
    }

    func test_forEachElement() {

        enum TestKey: EnvironmentKey, Equatable {
            static let defaultValue: Int = 0
        }

        struct SingleChildElement: Element {

            var child: Element

            var content: ElementContent {
                .init(child: child)
            }

            func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
                nil
            }
        }

        struct ByMeasuringElement: Element {

            static let element = Row {
                Column {
                    Spacer()
                    Empty()
                }
            }

            var content: ElementContent {
                .init(byMeasuring: Self.element)
            }

            func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
                nil
            }
        }

        /// The below element contains child element of every `ContentStorage`
        /// type, to ensure they all implement `forEachElement` correctly.

        let element = AdaptedEnvironment( /// `EnvironmentAdaptingStorage`
            key: TestKey.self,
            value: 1,
            wrapping: Row { /// `Builder`

                Column {
                    Empty() /// `MeasurableStorage`
                }

                Column {}

                GeometryReader { proxy in /// `LazyStorage`
                    Spacer()
                }

                SingleChildElement( /// `SingleChildStorage`
                    child: Empty()
                )

                ByMeasuringElement() /// `MeasureNestedElementStorage`
            }
        )

        // TODO: MeasureNestedElementStorage

        let tree = ElementStateTree(name: "Testing")

        let state = tree.performLayout(with: element, appearsInFinalLayout: true)

        let size = CGSize(width: 100, height: 100)

        let nodes = state.layout(in: size, with: .empty) { env in
            element.content.performLayout(in: size, appearsInFinalLayout: true, with: env, state: state)
        }

        var identifiers = [ElementIdentifier]()

        element.content.forEachElement(
            in: size,
            with: .empty,
            children: nodes,
            state: state,
            forEach: { context in
                identifiers.append(context.layoutNode.identifier)
            }
        )

        XCTAssertEqual(
            identifiers, [
                .identifier(for: Row.self, key: nil, count: 1),
                .identifier(for: Column.self, key: nil, count: 1),
                .identifier(for: Empty.self, key: nil, count: 1),
                .identifier(for: Column.self, key: nil, count: 2),
                .identifier(for: GeometryReader.self, key: nil, count: 1),
                .identifier(for: Spacer.self, key: nil, count: 1),
                .identifier(for: SingleChildElement.self, key: nil, count: 1),
                .identifier(for: Empty.self, key: nil, count: 1),
                .identifier(for: ByMeasuringElement.self, key: nil, count: 1),
            ]
        )
    }

    func test_measurementOnlyChild() {
        let element = SingleChildElement(child: MeasurableElement())
        let content = ElementContent(byMeasuring: element)

        let size = content.measure(in: SizeConstraint(width: .atMost(20.0), height: .atMost(20.0)))
        XCTAssertEqual(size.width, 20.0)
        XCTAssertEqual(size.height, 20.0)

        let layouts = content.performLayout(
            in: size,
            appearsInFinalLayout: false,
            with: .empty,
            state: ElementState(
                parent: nil,
                delegate: nil,
                identifier: .identifier(for: element, key: nil, count: 0),
                element: element,
                signpostRef: NSObject(),
                name: "",
                kind: .regular
            )
        )
        XCTAssertTrue(layouts.isEmpty)
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

private struct SingleChildElement: Element {
    let child: Element

    var content: ElementContent {
        .init(child: child)
    }

    func backingViewDescription(with context: BlueprintUI.ViewDescriptionContext) -> BlueprintUI.ViewDescription? {
        nil
    }
}
