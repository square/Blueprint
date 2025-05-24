import BlueprintUI
import UIKit
import XCTest

final class LayoutTraitsTests: XCTestCase {
    func test_traitPropagation() {
        let element = OptionalTraitElement(
            children: [
                (Empty(), 1),
                (Empty(), 2),
                (Empty(), nil),
            ]
        )

        let size = element.content.measure(in: .unconstrained)

        XCTAssertEqual(size, CGSize(width: 3, height: 3))
    }

    func test_multiTraits() {
        let element = MultiTraitElement(
            children: [
                (Empty(), 1, 2),
                (Empty(), 2, 3),
                (Empty(), 3, 4),
            ]
        )

        let size = element.content.measure(in: .unconstrained)

        XCTAssertEqual(size, CGSize(width: 15, height: 15))
    }

    // single trait propagation is covered by all the legacy layout tests
}

private enum FooTrait: LayoutTraitsKey {
    static var defaultValue: Int = 0
}

private enum BarTrait: LayoutTraitsKey {
    static var defaultValue: Int = 0
}

private struct OptionalTraitElement: Element {
    var children: [(Element, Int?)] = []

    var content: ElementContent {
        ElementContent(layout: FooBarSizingLayout()) { builder in
            for (element, foo) in children {
                if let foo = foo {
                    builder.add(
                        traitsType: FooTrait.self,
                        traits: foo,
                        element: element
                    )
                } else {
                    builder.add(element: element)
                }
            }
        }
    }

    func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        nil
    }
}

private struct MultiTraitElement: Element {
    var children: [(element: Element, foo: Int, bar: Int)] = []

    var content: ElementContent {
        ElementContent(layout: FooBarSizingLayout()) { builder in
            for (element, foo, bar) in children {
                builder.add(
                    traits: .empty
                        .setting(key: FooTrait.self, to: foo)
                        .setting(key: BarTrait.self, to: bar),
                    element: element
                )
            }
        }
    }

    func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        nil
    }
}

private struct FooBarSizingLayout: Layout {
    func measure(
        in constraint: SizeConstraint,
        items: [(traits: (), content: any Measurable)]
    ) -> CGSize {
        .zero
    }

    func layout(
        size: CGSize,
        items: [(traits: (), content: any Measurable)]
    ) -> [LayoutAttributes] {
        items.map { _ in .init() }
    }

    func sizeThatFits(
        proposal: SizeConstraint,
        subelements: Subelements,
        environment: Environment,
        cache: inout ()
    ) -> CGSize {
        let fooBarCount = subelements.map { subelement in
            subelement[FooTrait.self] + subelement[BarTrait.self]
        }
        .reduce(0, +)

        return CGSize(width: fooBarCount, height: fooBarCount)
    }

    func placeSubelements(
        in size: CGSize,
        subelements: Subelements,
        environment: Environment,
        cache: inout ()
    ) {}
}
