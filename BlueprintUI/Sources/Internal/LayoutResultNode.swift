import UIKit

extension Element {

    /// Build a fully laid out element tree with complete layout attributes
    /// for each element.
    ///
    /// - Parameter layoutAttributes: The layout attributes to assign to the
    ///   root element.
    ///
    /// - Returns: A layout result
    func layout(identifier : ElementIdentifier, layoutAttributes: LayoutAttributes, environment: Environment) -> LayoutResultNode {
        return LayoutResultNode(
            element: self,
            identifier: identifier,
            layoutAttributes: layoutAttributes,
            content: content,
            environment: environment
        )
    }

}

/// Represents a tree of elements with complete layout attributes
struct LayoutResultNode {
    
    /// The element that was laid out
    var element: Element
    
    var identifier : ElementIdentifier
    
    /// Diagnostic information about the layout process.
    var diagnosticInfo: DiagnosticInfo
    
    /// The layout attributes for the element
    var layoutAttributes: LayoutAttributes

    /// The element's children.
    var children: [LayoutResultNode]
    
    init(element: Element, identifier : ElementIdentifier, layoutAttributes: LayoutAttributes, content: ElementContent, environment: Environment) {

        self.element = element
        self.identifier = identifier
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
    func resolve() -> [NativeViewNode] {

        let resolvedChildContent: [NativeViewNode] = children
            .flatMap { layoutResultNode in

                return layoutResultNode
                    .resolve()
                    .map { viewDescriptionNode in
                        return viewDescriptionNode
                    }
        }

        let subtreeExtent: CGRect? = children
            .reduce(into: nil) { (rect, node) in
                rect = rect?.union(node.layoutAttributes.frame) ?? node.layoutAttributes.frame
            }

        let viewDescription = element.backingViewDescription(
            bounds: layoutAttributes.bounds,
            subtreeExtent: subtreeExtent)

        if let viewDescription = viewDescription {
            let node = NativeViewNode(
                identifier: identifier,
                content: viewDescription,
                layoutAttributes: layoutAttributes,
                children: resolvedChildContent
            )
            
            return [node]
        } else {
            return resolvedChildContent.map { node in
                var transformedNode = node
                transformedNode.layoutAttributes = transformedNode.layoutAttributes.within(layoutAttributes)
                return transformedNode
            }
        }

    }
    
}
