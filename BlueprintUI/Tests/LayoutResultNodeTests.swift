import XCTest
@testable import BlueprintUI


final class LayoutResultNodeTests: XCTestCase {

    func testResolveFlattensNonViewBackedElements() {

        /// Three levels of abstract containers (insetting by 10pt each)
        let testHierarchy = AbstractElement(
            AbstractElement(
                AbstractElement(
                    ConcreteElement()
                )
            )
        )

        let layoutResult = testHierarchy.layout(frame: CGRect(x: 0, y: 0, width: 160, height: 160))
        let viewNodes = layoutResult.resolve()

        XCTAssertEqual(viewNodes.count, 1)

        let viewNode = viewNodes[0]

        XCTAssertEqual(viewNode.node.layoutAttributes.frame, CGRect(x: 30, y: 30, width: 100, height: 100))

    }

}


fileprivate struct AbstractElement: Element {

    var wrappedElement: Element

    init(_ wrappedElement: Element) {
        self.wrappedElement = wrappedElement
    }

    func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        return nil
    }

    var content: ElementContent {
        return ElementContent(child: wrappedElement, layout: Layout())
    }

    private struct Layout: SingleChildLayout {
        func measure(
            child: Measurable,
            in constraint : SizeConstraint,
            with context: LayoutContext
        ) -> CGSize
        {
            .zero
        }
        
        func layout(
            child: Measurable,
            in size : CGSize,
            with context : LayoutContext
        ) -> LayoutAttributes
        {
            LayoutAttributes(frame: CGRect(origin: .zero, size: size).insetBy(dx: 10, dy: 10))
        }
    }

}


fileprivate struct ConcreteElement: Element {

    func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        return UIView.describe { _ in }
    }

    var content: ElementContent {
        return ElementContent(intrinsicSize: .zero)
    }

}
