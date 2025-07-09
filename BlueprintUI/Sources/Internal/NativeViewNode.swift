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

    /// The environment at this node in the tree.
    var environment: Environment

    /// The layout attributes for this content (relative to the parent's layout
    /// attributes).
    var layoutAttributes: LayoutAttributes

    /// The children of this node.
    var children: [(path: ElementPath, node: NativeViewNode)]

    init(
        content: ViewDescription,
        environment: Environment,
        layoutAttributes: LayoutAttributes,
        children: [(path: ElementPath, node: NativeViewNode)]
    ) {

        viewDescription = content
        self.environment = environment
        self.layoutAttributes = layoutAttributes
        self.children = children
    }

    /// Recursively rounds this node's layout frame and all its children to snap to pixel boundaries.
    ///
    /// - Parameters:
    ///   - origin: The global origin to offset the frame by before rounding. This offset is used to ensure that
    ///     positive and negative frame coordinates both round away from zero.
    ///   - correction: The amount of rounding correction to apply to the origin before rounding, to account for the
    ///     rounding applied to this node's parent.
    ///   - scale: The screen scale to use when rounding.
    mutating func round(from origin: CGPoint, correction: CGRect, scale: CGFloat) {
        // Per the docs for UIView.frame:
        // > If the transform property is not the identity transform, the value of this property is undefined
        // > and therefore should be ignored.
        // So we do not attempt to snap the frame to pixel bounds in this case.
        guard CATransform3DIsIdentity(layoutAttributes.transform) else {
            return
        }

        let childCorrection = layoutAttributes.round(
            from: origin,
            correction: correction,
            scale: scale,
            behavior: viewDescription.frameRoundingBehavior
        )

        let childOrigin = origin + layoutAttributes.frame.origin

        environment.roundingCorrection = childCorrection
        environment.roundingOrigin = childOrigin

        for i in children.indices {
            children[i].node.round(from: childOrigin, correction: childCorrection, scale: scale)
        }
    }
}
