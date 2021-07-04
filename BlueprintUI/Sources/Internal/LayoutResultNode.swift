import UIKit


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

    init(
        root: Element,
        layoutAttributes: LayoutAttributes,
        environment: Environment,
        measurementViews: LayoutContext.MeasurementViews,
        states : ElementState
    ) {
        self.init(
            element: root,
            layoutAttributes: layoutAttributes,
            environment: environment,
            children: root.content.performLayout(
                in: layoutAttributes.frame.size,
                with: .init(
                    environment: environment,
                    measurementViews: measurementViews
                ),
                states: states
            )
        )
    }
}


extension LayoutResultNode {

    /// Returns the flattened tree of view descriptions (any element that does not return
    /// a view description will be skipped).
    func resolve() -> [(path: ElementPath, node: NativeViewNode)] {

        let resolvedChildContent: [(path: ElementPath, node: NativeViewNode)] = children
            .flatMap { identifier, layoutResultNode in

                return layoutResultNode
                    .resolve()
                    .map { path, viewDescriptionNode in
                        return (path: path.prepending(identifier: identifier), node: viewDescriptionNode)
                    }
        }

        let subtreeExtent: CGRect? = children
            .reduce(into: nil) { (rect, child) in
                rect = rect?.union(child.node.layoutAttributes.frame) ?? child.node.layoutAttributes.frame
            }

        let viewDescription = element.backingViewDescription(
            with: .init(
                bounds: layoutAttributes.bounds,
                subtreeExtent: subtreeExtent,
                environment: environment
            )
        )

        if let viewDescription = viewDescription {
            let node = NativeViewNode(
                content: viewDescription,
                environment: environment,
                layoutAttributes: layoutAttributes,
                children: resolvedChildContent
            )
            
            return [(path: .empty, node: node)]
        } else {
            return resolvedChildContent.map { (path, node) -> (path: ElementPath, node: NativeViewNode) in
                var transformedNode = node
                transformedNode.layoutAttributes = transformedNode.layoutAttributes.within(layoutAttributes)
                return (path, transformedNode)
            }
        }
    }
}
