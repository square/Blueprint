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
        return LayoutResultNode(
            element: self,
            layoutAttributes: layoutAttributes,
            content: content,
            environment: environment)
    }

}

/// Represents a tree of elements with complete layout attributes
struct LayoutResultNode {
    
    /// The element that was laid out
    var element: Element
    
    /// Diagnostic information about the layout process.
    var diagnosticInfo: DiagnosticInfo
    
    /// The layout attributes for the element
    var layoutAttributes: LayoutAttributes

    /// The element's children.
    var children: [(identifier: ElementIdentifier, node: LayoutResultNode)]
    
    init(element: Element, layoutAttributes: LayoutAttributes, content: ElementContent, environment: Environment) {

        self.element = element
        self.layoutAttributes = layoutAttributes

        let layoutBeginTime = DispatchTime.now()
        children = content.performLayout(attributes: layoutAttributes, environment: environment)
        let layoutEndTime = DispatchTime.now()
        let layoutDuration = layoutEndTime.uptimeNanoseconds - layoutBeginTime.uptimeNanoseconds
        diagnosticInfo = LayoutResultNode.DiagnosticInfo(layoutDuration: layoutDuration)

    }

}

extension LayoutResultNode {
    
    struct DiagnosticInfo {
        
        var layoutDuration: UInt64
        
        init(layoutDuration: UInt64) {
            self.layoutDuration = layoutDuration
        }
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

                        let component = ElementPath.Component(
                            elementType: type(of: layoutResultNode.element),
                            identifier: identifier)

                        return (path: path.prepending(component: component), node: viewDescriptionNode)
                    }
        }

        let subtreeExtent: CGRect? = children
            .map { $0.node }
            .reduce(into: nil) { (rect, node) in
                rect = rect?.union(node.layoutAttributes.frame) ?? node.layoutAttributes.frame
            }

        let viewDescription = element.backingViewDescription(
            bounds: layoutAttributes.bounds,
            subtreeExtent: subtreeExtent)

        if let viewDescription = viewDescription {
            let node = NativeViewNode(
                content: viewDescription,
                layoutAttributes: layoutAttributes,
                children: resolvedChildContent)
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
