import UIKit

/// Represents a flattened hierarchy of view descriptions and accompanying layout attributes which are derived from an
/// element hierarchy.
///
/// Each child contains the path to the element that provided it, relative to its parent.
///
/// Example: for a given element hierarchy
///
/// - "A" *
///  - "B"
///   - "C"
///    - "D" *
///
/// in which content-providing elements are designated by asterisks:
///
/// The resulting content nodes will be shaped like this.
///
/// - (path: ["A"])
///  - (path: ["B","C","D"])
struct NativeViewNode {
    
    /// The view description returned by this node
    var viewDescription: ViewDescription
    
    /// The layout attributes for this content (relative to the parent's layout
    /// attributes).
    var layoutAttributes: LayoutAttributes

    /// The children of this node.
    var children: [(path: ElementPath, node: NativeViewNode)]
    
    init(
        content: ViewDescription,
        layoutAttributes: LayoutAttributes,
        children: [(path: ElementPath, node: NativeViewNode)]) {
        
        self.viewDescription = content
        self.layoutAttributes = layoutAttributes
        self.children = children
    }
    
}
