import UIKit

extension Element {

    /// Build a fully laid out element tree with complete layout attributes
    /// for each element.
    ///
    /// - Parameters:
    ///   - frame: the root element's frame
    ///   - environment: the root environment
    ///   - layoutMode: the mode to use for layout
    /// - Returns: A layout result
    func layout(frame: CGRect, environment: Environment, layoutMode: LayoutMode) -> LayoutResultNode {
        switch layoutMode {
        case .legacy:
            return legacyLayout(
                layoutAttributes: LayoutAttributes(frame: frame),
                environment: environment
            )

        case .caffeinated(let options):
            return caffeinatedLayout(
                frame: frame,
                environment: environment,
                node: LayoutTreeNode(
                    path: "\(type(of: self))",
                    signpostRef: SignpostToken(),
                    options: options
                )
            )
        }
    }

    private func legacyLayout(layoutAttributes: LayoutAttributes, environment: Environment) -> LayoutResultNode {
        let cache = CacheFactory.makeCache(name: "\(type(of: self))")
        let children = content.performLegacyLayout(
            attributes: layoutAttributes,
            environment: environment,
            cache: cache
        )

        return LayoutResultNode(
            identifier: .identifierFor(singleChild: self),
            element: self,
            layoutAttributes: layoutAttributes,
            environment: environment,
            children: children
        )
    }

    private func caffeinatedLayout(
        frame: CGRect,
        environment: Environment,
        node: LayoutTreeNode
    ) -> LayoutResultNode {
        let children = content.performCaffeinatedLayout(
            frame: frame,
            environment: environment,
            node: node
        )

        return LayoutResultNode(
            identifier: .identifierFor(singleChild: self),
            element: self,
            layoutAttributes: LayoutAttributes(frame: frame),
            environment: environment,
            children: children
        )
    }
}

/// Represents a tree of elements with complete layout attributes
struct LayoutResultNode {

    /// The identifier for the element within its parent.
    var identifier: ElementIdentifier

    /// The element that was laid out
    var element: ElementState.LatestElement

    /// The layout attributes for the element
    var layoutAttributes: LayoutAttributes

    var environment: Environment

    /// The element's children.
    var children: [(identifier: ElementIdentifier, node: LayoutResultNode)]

    init(
        identifier: ElementIdentifier,
        element: Element,
        layoutAttributes: LayoutAttributes,
        environment: Environment,
        children: [(identifier: ElementIdentifier, node: LayoutResultNode)]
    ) {
        self.identifier = identifier
        self.element = ElementState.LatestElement(element)
        self.layoutAttributes = layoutAttributes
        self.environment = environment
        self.children = children
    }

    init(
        identifier: ElementIdentifier,
        layoutAttributes: LayoutAttributes,
        environment: Environment,
        state: ElementState
    ) {
        self.init(
            identifier: identifier,
            element: state.element.latest,
            layoutAttributes: layoutAttributes,
            environment: environment,
            children: state.elementContent.performCachedCaffeinatedLayout(
                in: layoutAttributes.frame.size,
                with: environment,
                state: state
            ).caffeinatedBridgedWithIdentity
        )
    }
}

extension LayoutResultNode {

    /// Returns the flattened tree of view descriptions (any element that does not return
    /// a view description will be skipped, and relevant layout attributes will be propagated).
    func resolve() -> [(path: ElementPath, node: NativeViewNode)] {

        // Recursively resolve child nodes in a depth-first manner, as
        // complete layout data for all children is required to perform the
        // appropriate computations.
        let resolvedChildContent: [(path: ElementPath, node: NativeViewNode)] = children
            .flatMap { identifier, layoutResultNode in

                layoutResultNode
                    .resolve()
                    .map { path, viewDescriptionNode in
                        // Propagate the child identifier
                        (path: path.prepending(identifier: identifier), node: viewDescriptionNode)
                    }
            }

        // Determine the 'extent' of any child nodes. This is
        // the minimal-area rectangle containing all child frames.
        let subtreeExtent: CGRect? = children
            .map { $0.node }
            .reduce(into: nil) { rect, node in
                rect = rect?.union(node.layoutAttributes.frame) ?? node.layoutAttributes.frame
            }

        // Get the backing view description for the current node (if any),
        // populated with relevant layout data.
        let viewDescription = element.latest.backingViewDescription(
            with: .init(
                bounds: layoutAttributes.bounds,
                subtreeExtent: subtreeExtent,
                environment: environment
            )
        )

        if let viewDescription = viewDescription {
            // If this node has a backing view description, create a `NativeViewNode`
            // to represent it.
            let node = NativeViewNode(
                content: viewDescription,
                environment: environment,
                layoutAttributes: layoutAttributes,
                children: resolvedChildContent
            )

            return [(path: .empty, node: node)]
        } else {
            // Otherwise this node simply provides layout attributes, so
            // propagate this information to any child nodes. For example, if
            // the current node's `element` was an `Inset`, the child layout
            // attributes would be updated to account for the appropriate bounds
            // adjustment.
            return resolvedChildContent.map { path, node -> (path: ElementPath, node: NativeViewNode) in
                var transformedNode = node
                transformedNode.layoutAttributes = transformedNode.layoutAttributes.within(layoutAttributes)
                return (path, transformedNode)
            }
        }

    }

    /// Recursively dump layout tree, for debugging.
    func dump(
        depth: Int = 0,
        visit: (_ depth: Int, _ identifier: String, _ frame: CGRect) -> Void
    ) {
        for child in children {
            let attributes = child.node.layoutAttributes

            visit(depth, "\(child.identifier)", attributes.frame)

            child.node.dump(depth: depth + 1, visit: visit)
        }
    }

}

extension [LayoutResultNode] {

    var caffeinatedBridgedWithIdentity: [(ElementIdentifier, LayoutResultNode)] {
        map {
            (ElementIdentifier.identifier(for: $0.element.latest, key: nil, count: count), $0)
        }
    }

}
