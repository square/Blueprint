import BlueprintUI
import XCTest
@testable import BlueprintUICommonControls


class BoxTests: XCTestCase {

    func test_backgroundColor() {
        let box = Box(backgroundColor: .red)
        compareSnapshot(
            of: box,
            size: CGSize(width: 100, height: 100),
            identifier: "red"
        )

        compareSnapshot(
            of: Box(backgroundColor: .clear),
            size: CGSize(width: 100, height: 100),
            identifier: "clear"
        )
    }

    func test_cornerStyle() {
        do {
            var box = Box()
            box.backgroundColor = .blue
            box.cornerStyle = .capsule
            compareSnapshot(
                of: box,
                size: CGSize(width: 200, height: 100),
                identifier: "wideCapsule"
            )

            compareSnapshot(
                of: box,
                size: CGSize(width: 100, height: 200),
                identifier: "longCapsule"
            )
        }

        do {
            var box = Box()
            box.backgroundColor = .blue
            box.cornerStyle = .rounded(radius: 10.0)
            compareSnapshot(
                of: box,
                size: CGSize(width: 100, height: 100),
                identifier: "rounded"
            )
        }
    }

    func test_shadow() {
        var element = InsettingElement()
        element.box.backgroundColor = UIColor.green
        element.box.cornerStyle = .rounded(radius: 10.0)
        element.box.shadowStyle = .simple(radius: 8.0, opacity: 1.0, offset: .zero, color: .magenta)

        compareSnapshot(
            of: element,
            size: CGSize(width: 100, height: 100)
        )
    }

    func test_borders() {

        do {
            var box = Box()
            box.backgroundColor = .blue
            box.borderStyle = .solid(color: .orange, width: 1.0)
            compareSnapshot(
                of: box,
                size: CGSize(width: 100, height: 100),
                identifier: "square"
            )
        }

        do {
            var box = Box()
            box.backgroundColor = .blue
            box.cornerStyle = .rounded(radius: 10.0)
            box.borderStyle = .solid(color: .orange, width: 1.0)
            compareSnapshot(
                of: box,
                size: CGSize(width: 100, height: 100),
                identifier: "rounded"
            )
        }
    }

    func test_displaysContent() {
        var element = InsettingElement()
        element.box.wrappedElement = Label(text: "Hello, world")
        compareSnapshot(
            of: element,
            size: CGSize(width: 100, height: 100)
        )
    }

    func test_largeCornerRadius() {
        var element = InsettingElement()
        element.box.backgroundColor = .blue
        element.box.cornerStyle = .rounded(radius: 100)
        element.box.shadowStyle = .simple(radius: 2, opacity: 1, offset: .zero, color: .red)
        compareSnapshot(
            of: element,
            size: CGSize(width: 120, height: 100)
        )
    }

}



private struct InsettingElement: Element {

    var box: Box = Box()

    func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        nil
    }

    var content: ElementContent {
        ElementContent(child: box, layout: Layout())
    }

    private struct Layout: SingleChildLayout {
        func measure(in constraint: SizeConstraint, child: Measurable) -> CGSize {
            .zero
        }

        func layout(size: CGSize, child: Measurable) -> LayoutAttributes {
            LayoutAttributes(frame: CGRect(origin: .zero, size: size).insetBy(dx: 20, dy: 20))
        }

        func sizeThatFits(proposal: SizeConstraint, subelement: LayoutSubelement, cache: inout ()) -> CGSize {
            .zero
        }

        func placeSubelement(in size: CGSize, subelement: LayoutSubelement, cache: inout ()) {
            subelement.place(in: CGRect(origin: .zero, size: size).insetBy(dx: 20, dy: 20))
        }
    }

}
