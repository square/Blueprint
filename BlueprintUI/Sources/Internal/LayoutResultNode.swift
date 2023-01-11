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

    func layout(frame: CGRect, environment: Environment, layoutMode: LayoutMode) -> LayoutResultNode {
        switch layoutMode {
        case .standard:
            return layout(layoutAttributes: LayoutAttributes(frame: frame), environment: environment)
        case .singlePass:
            return singlePassLayout(
                proposal: .init(frame.size),
                context: SPLayoutContext(
                    attributes: LayoutAttributes(frame: frame),
                    environment: environment,
                    // TODO: Hoist up?
                    cache: .init(path: "\(type(of: self))")
                )
            )
        case .strictSinglePass:
            return strictLayout(frame: frame, environment: environment)
        }
    }

    func singlePassLayout(proposal: SizeConstraint, context: SPLayoutContext) -> LayoutResultNode {
        let layouts = content.performSinglePassLayout(
            proposal: proposal,
            context: context
        )

        return LayoutResultNode(
            element: self,
            layoutAttributes: context.attributes,
            environment: context.environment,
            children: layouts.map { (identifier: $0.identifier, node: $0.node) }
        )
    }
    
    func strictLayout(frame: CGRect, environment: Environment) -> LayoutResultNode {
        let attributes = LayoutAttributes(frame: frame)
        let cache = StrictCacheNode(path: "\(type(of: self))")
        let context = StrictLayoutContext(
            path: .empty,
            cache: cache,
            proposedSize: .init(frame.size),
            mode: AxisVarying(horizontal: .fill, vertical: .fill)
        )

        let subtree = content.performStrictLayout(
            in: context,
            environment: environment
        )

        subtree.dump(id: "\(type(of: self))", position: .zero, context: context, correction: .zero)

        let children = subtree
            .resolve()

        let root = LayoutResultNode(
            element: self,
            layoutAttributes: attributes,
            environment: environment,
            children: children
        )

//        root.dump()
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

    /// Recursively dump layout tree, for debugging. By default, prints to stdout.
    @_spi(Debugging)
    public func dump(
        depth: Int = 0,
        visit: ((_ depth: Int, _ identifier: String, _ frame: CGRect) -> Void) = { depth, identifier, frame in
            let origin = "x \(frame.origin.x), y \(frame.origin.y)"
            let size = "\(frame.size.width) × \(frame.size.height)"
            let indent = String(repeating: "  ", count: depth)
            print("\(indent)\(identifier) \(origin), \(size)")
        }
    ) {
        for child in children {
            let attributes = child.node.layoutAttributes

            let debugScope = child.node.environment[DebugScopeKey.self]

            let name = (debugScope + ["\(child.identifier)"]).joined(separator: "/")

            visit(depth, name, attributes.frame)

            child.node.dump(depth: depth + 1, visit: visit)
        }
    }

}
