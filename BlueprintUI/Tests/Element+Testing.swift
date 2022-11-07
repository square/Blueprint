import QuartzCore
@testable import BlueprintUI

extension Element {
    /// Build a fully laid out element tree with complete layout attributes
    /// for each element.
    ///
    /// - Parameter frame: The frame to assign to the root element.
    ///
    /// - Returns: A layout result
    func layout(frame: CGRect, environment: Environment = .empty) -> LayoutResultNode {
        layout(layoutAttributes: LayoutAttributes(frame: frame), environment: environment)
    }
}

extension ElementContent {
    /// A convenience method to measure the required size of this element's content,
    /// using a default environment.
    /// - Parameters:
    ///   - constraint: The size constraint.
    /// - returns: The layout size needed by this content.
    func measure(in constraint: SizeConstraint) -> CGSize {
        measure(in: constraint, environment: .empty)
    }

    /// A convenience wrapper to perform layout during testing, using a default `Environment` and
    /// a new cache.
    func testLayout(in size: CGSize) -> [LayoutResultNode] {

        let element = LayoutElement(content: self)

        let state = ElementState(
            parent: nil,
            delegate: nil,
            identifier: .identifierFor(singleChild: element),
            element: element,
            depth: 0,
            signpostRef: NSObject(),
            name: "Testing"
        )

        return performLayout(
            in: size,
            with: .empty,
            state: state
        )
    }

    private struct LayoutElement: Element {

        var content: ElementContent

        func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
            nil
        }
    }
}
