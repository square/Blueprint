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
        layout(
            frame: frame,
            environment: environment,
            layoutMode: RenderContext.current?.layoutMode ?? .default
        )
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
    func testLayout(attributes: LayoutAttributes) -> [(identifier: ElementIdentifier, node: LayoutResultNode)] {
        let layoutMode = RenderContext.current?.layoutMode ?? .default
        switch layoutMode {
        case .legacy:
            return performLegacyLayout(
                attributes: attributes,
                environment: .empty,
                cache: CacheFactory.makeCache(name: "test")
            )
        case .caffeinated(let options):
            return performCaffeinatedLayout(
                frame: attributes.frame,
                environment: .empty,
                node: LayoutTreeNode(path: "test", signpostRef: SignpostToken(), options: options)
            )
        }
    }
}
