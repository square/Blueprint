import UIKit

extension Element {

    /// Build a fully laid out element tree with complete layout attributes
    /// for each element.
    ///
    /// - Parameter layoutAttributes: The layout attributes to assign to the
    ///   root element.
    ///
    /// - Returns: A layout result
    func layout(layoutAttributes: LayoutAttributes, environment: Environment) -> LayoutResultNode {
        LayoutResultNode(
            root: self,
            layoutAttributes: layoutAttributes,
            environment: environment
        )
    }

}

/// Represents a tree of elements with complete layout attributes
struct LayoutResultNode {

    /// The element that was laid out
    var element: Element

    /// The layout attributes for the element
    var layoutAttributes: LayoutAttributes

    var environment: Environment

    /// The element's children.
    var children: [(identifier: ElementIdentifier, node: LayoutResultNode)]

    init(
        element: Element,
        layoutAttributes: LayoutAttributes,
        environment: Environment,
        children: [(identifier: ElementIdentifier, node: LayoutResultNode)]
    ) {
        self.element = element
        self.layoutAttributes = layoutAttributes
        self.environment = environment
        self.children = children
    }

    init(root: Element, layoutAttributes: LayoutAttributes, environment: Environment) {
        let cache = CacheFactory.makeCache(name: "\(type(of: root))", content: { root.content })

        self.init(
            element: root,
            layoutAttributes: layoutAttributes,
            environment: environment,
            children: cache.content.performLayout(
                attributes: layoutAttributes,
                environment: environment,
                cache: cache
            )
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
        let viewDescription = element.backingViewDescription(
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

}
