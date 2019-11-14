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
    
    mutating func roundToPixelBoundaries(screenScale: CGFloat, localOriginInScreenSpace: CGPoint) {
        guard CATransform3DIsIdentity(layoutAttributes.transform) else {
            return
        }
        let roundedLayoutAttributes = layoutAttributes.roundedToPixelBoundaries(
            screenScale: screenScale,
            localOriginInScreenSpace: localOriginInScreenSpace)
        
        // Determine the offset in the local coordinate space due to rounding. This will be used to counteract the rounding
        // for children of this node.
        let offset = CGPoint(
            x: layoutAttributes.frame.minX - roundedLayoutAttributes.frame.minX,
            y: layoutAttributes.frame.minY - roundedLayoutAttributes.frame.minY)
        
        print(offset)
        
        // Apply the rounded layout attributes
        layoutAttributes = roundedLayoutAttributes
        
        // Determine the local origin in screen space for children of this node (post rounding)
        let subtreeLocalOriginInScreenSpace = CGPoint(
            x: localOriginInScreenSpace.x + layoutAttributes.frame.minX,
            y: localOriginInScreenSpace.y + layoutAttributes.frame.minY)
        
        for i in children.indices {
            
            // Apply an offset to children so they remain unaffected by the rounding that just ocurred, relative to screen space.
            // Preventing the parent's rounding from impacting children ensures that each view, no matter its depth, snaps
            // as close to its original frame as possible (we would otherwise accumulate rounding behavior as we traversed
            // the tree).
            children[i].node.layoutAttributes.frame.origin.x += offset.x
            children[i].node.layoutAttributes.frame.origin.y += offset.y
            
            // Finally, allow each child to snap to pixel boundaries in screen space.
            children[i].node.roundToPixelBoundaries(screenScale: screenScale, localOriginInScreenSpace: subtreeLocalOriginInScreenSpace)
        }

    }
    
}
