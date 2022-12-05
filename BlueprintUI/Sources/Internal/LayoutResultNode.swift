import UIKit

/// Represents a tree of elements with complete layout attributes
struct LayoutResultNode {

    /// The element that was laid out. This is a reference to a
    /// `LatestElement` box, so that even in cached `LayoutResultNode` values,
    /// we will recieve the latest element from the layout pass.
    var element: ElementState.LatestElement

    /// The identifier for the element within its parent.
    var identifier: ElementIdentifier

    /// The layout attributes for the element
    var layoutAttributes: LayoutAttributes

    /// If the layout node and its children appear in the final layout.
    /// For measurement-only nodes, this is false.
    var appearsInFinalLayout: Bool

    /// The environment for the element.
    var environment: Environment

    /// The element's children.
    var children: [LayoutResultNode]

    init(
        identifier: ElementIdentifier,
        layoutAttributes: LayoutAttributes,
        appearsInFinalLayout: Bool,
        environment: Environment,
        element: ElementState.LatestElement,
        children: [LayoutResultNode]
    ) {
        self.identifier = identifier
        self.layoutAttributes = layoutAttributes
        self.appearsInFinalLayout = appearsInFinalLayout
        self.environment = environment
        self.element = element

        self.children = children
    }

    init(
        identifier: ElementIdentifier,
        layoutAttributes: LayoutAttributes,
        appearsInFinalLayout: Bool,
        environment: Environment,
        state: ElementState
    ) {
        self.init(
            identifier: identifier,
            layoutAttributes: layoutAttributes,
            appearsInFinalLayout: appearsInFinalLayout,
            environment: environment,
            element: state.element,
            children: state.element.latest.content.performLayout(
                in: layoutAttributes.frame.size,
                appearsInFinalLayout: appearsInFinalLayout,
                with: environment,
                state: state
            )
        )
    }
}


extension LayoutResultNode {

    /// Returns the flattened tree of view descriptions (any element that does not return
    /// a view description will be skipped, and relevant layout attributes will be propagated).
    func resolve() -> [(path: ElementPath, node: NativeViewNode)] {

        guard appearsInFinalLayout else {
            return []
        }

        // Recursively resolve child nodes in a depth-first manner, as
        // complete layout data for all children is required to perform the
        // appropriate computations.
        let resolvedChildContent: [(path: ElementPath, node: NativeViewNode)] = children
            .flatMap { layoutResultNode in

                layoutResultNode
                    .resolve()
                    .map { path, viewDescriptionNode in
                        // Propagate the child identifier
                        (path: path.prepending(identifier: layoutResultNode.identifier), node: viewDescriptionNode)
                    }
            }

        // Determine the 'extent' of any child nodes. This is
        // the minimal-area rectangle containing all child frames.
        let subtreeExtent: CGRect? = children
            .reduce(into: nil) { rect, child in
                rect = rect?.union(child.layoutAttributes.frame) ?? child.layoutAttributes.frame
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
}

