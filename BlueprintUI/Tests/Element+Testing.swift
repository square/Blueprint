@testable import BlueprintUI
import QuartzCore

extension Element {
    /// Build a fully laid out element tree with complete layout attributes
    /// for each element.
    ///
    /// - Parameter frame: The frame to assign to the root element.
    ///
    /// - Returns: A layout result
    func layout(frame: CGRect, environment: Environment = .empty) -> LayoutResultNode {
        return layout(layoutAttributes: LayoutAttributes(frame: frame), environment: environment)
    }
}

extension ElementContent {
    /// A convenience method to measure the required size of this element's content,
    /// using a default environment.
    /// - Parameters:
    ///   - constraint: The size constraint.
    /// - returns: The layout size needed by this content.
    func measure(in constraint: SizeConstraint) -> CGSize {
        return measure(in: constraint, environment: .empty)
    }

    /// A convenience wrapper to perform layout during testing, using an default `Environment` and
    /// a new cache.
    func testLayout(attributes: LayoutAttributes) -> [(identifier: ElementIdentifier, node: LayoutResultNode)] {
        self.performLayout(
            attributes: attributes,
            environment: .empty,
            cache: CacheFactory.makeCache(name: "test")
        )
    }
}
