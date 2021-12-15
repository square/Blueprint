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

    func layout(frame: CGRect, environment: Environment, singlePass: Bool) -> LayoutResultNode {
        if singlePass {
            return singlePassLayout(frame: frame, environment: environment)
        } else {
            return layout(layoutAttributes: LayoutAttributes(frame: frame), environment: environment)
        }
    }

    func singlePassLayout(frame: CGRect, environment: Environment) -> LayoutResultNode {

        let attributes = LayoutAttributes(frame: frame)
        let context = SPLayoutContext(proposedSize: frame.size)
        let cache = CacheFactory.makeCache(name: "\(type(of: self))")

        let children = self.content.singlePassLayout(
            in: context,
            environment: environment,
            cache: cache
        )
        .resolve()

        let root = LayoutResultNode(
            element: self,
            layoutAttributes: attributes,
            environment: environment,
            children: children
        )

        root.dump()

        return root
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
        let cache = CacheFactory.makeCache(name: "\(type(of: root))")
        self.init(
            element: root,
            layoutAttributes: layoutAttributes,
            environment: environment,
            children: root.content.performLayout(
                attributes: layoutAttributes,
                environment: environment,
                cache: cache
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

                layoutResultNode
                    .resolve()
                    .map { path, viewDescriptionNode in
                        (path: path.prepending(identifier: identifier), node: viewDescriptionNode)
                    }
            }

        let subtreeExtent: CGRect? = children
            .map { $0.node }
            .reduce(into: nil) { rect, node in
                rect = rect?.union(node.layoutAttributes.frame) ?? node.layoutAttributes.frame
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
            return resolvedChildContent.map { path, node -> (path: ElementPath, node: NativeViewNode) in
                var transformedNode = node
                transformedNode.layoutAttributes = transformedNode.layoutAttributes.within(layoutAttributes)
                return (path, transformedNode)
            }
        }

    }

}

extension LayoutResultNode {
    func dump(depth: Int = 0) {
        for child in children {
            let attributes = child.node.layoutAttributes
            let origin = "x:\(attributes.frame.origin.x) y:\(attributes.frame.origin.y)"
            let size = "w:\(attributes.frame.size.width) h:\(attributes.frame.size.height)"
            let indent = String(repeating: "  ", count: depth)
            print("\(indent)\(child.identifier), \(origin) \(size)")
            child.node.dump(depth: depth + 1)
        }
    }
}
