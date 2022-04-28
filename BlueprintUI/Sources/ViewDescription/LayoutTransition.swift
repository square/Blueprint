import UIKit

/// The transition used when layout attributes change for a view during an
/// update cycle.
///
/// **'Inherited' transitions:** the 'inherited' transition is determined by searching up the tree (not literally, but
/// this is the resulting behavior). The nearest ancestor that defines an animation will be used, following this
/// logic:
/// - Ancestors with a layout transition of `none` will result in no inherited animation for their descendents.
/// - Ancestors in the tree with a layout transition of `inherited` will be skipped, and the search will continue
///   up the tree.
/// - Any ancestors in the tree with a layout transition of `inheritedWithFallback` will be used *if* they do not
///   themselves inherit a layout transition from one of their ancestors.
/// - Ancestors with a layout transition of `specific` will always be used for their descendents inherited
///   animation.
/// - If no ancestor is found that specifies a layout transition, but the containing `BlueprintView` has the `element`
///   property assigned from within a `UIKit` animation block, that animation will be used as the inherited animation.
public enum LayoutTransition {

    /// The view will never animate layout changes.
    case none

    /// Layout changes will always animate with the given attributes.
    case specific(AnimationAttributes = .default)

    /// The view will only animate layout changes if an inherited transition exists.
    case inherited

    /// The view will animate along with an inherited transition (if present) or the specified fallback attributes.
    case inheritedWithFallback(AnimationAttributes = .default)

}


extension LayoutTransition {

    func perform(_ animations: @escaping () -> Void) {

        switch self {
        case .inherited:
            animations()
        case .none:
            UIView.performWithoutAnimation(animations)
        case .inheritedWithFallback(let fallback):
            if UIView.isInAnimationBlock {
                animations()
            } else {
                fallback.perform(
                    animations: animations,
                    completion: {}
                )
            }
        case .specific(let attributes):
            attributes.perform(
                animations: animations,
                completion: {}
            )
        }

    }

}
