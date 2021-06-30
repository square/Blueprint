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
        return LayoutResultNode(
            root: self,
            layoutAttributes: LayoutAttributes(frame: frame),
            environment: environment,
            measurementViews: .init()
        )
    }
}

extension ElementContent {

    func measure(in constraint: SizeConstraint, environment: Environment = .empty) -> CGSize {
        measure(
            in: constraint,
            with: .rootContext(with: environment)
        )
    }

    /// A convenience wrapper to perform layout during testing, using a default `Environment` and
    /// a new cache.
    func testLayout(in size : CGSize) -> [(identifier: ElementIdentifier, node: LayoutResultNode)] {
        self.performLayout(
            in: size,
            with: .rootContext(),
            cache: CacheFactory.makeCache(name: "test")
        )
    }
}
