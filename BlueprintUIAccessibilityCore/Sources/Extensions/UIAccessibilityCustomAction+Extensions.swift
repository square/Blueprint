#if !os(watchOS) && !os(visionOS)
import UIKit

extension [UIAccessibilityCustomAction] {
    public func removingDuplicateActions() -> [UIAccessibilityCustomAction] {
        reduce(into: []) { result, action in
            if !result.contains(where: { $0.isEquivalent(to: action) }) {
                result.append(action)
            }
        }
    }
}

extension UIAccessibilityCustomAction {
    // We end up with custom actions that are equivalent but a pointer agnostic isEqual isn't implemented.
    fileprivate func isEquivalent(to other: UIAccessibilityCustomAction) -> Bool {
        // Start with pointer equality, in case they're identical objects.
        guard !isEqual(other) else { return true }

        if other.name != name {
            return false
        }

        if let ourTarget = target as? NSObject, let otherTarget = other.target as? NSObject {
            if !ourTarget.isEqual(otherTarget) {
                return false
            }
        } else if target != nil || other.target != nil {
            return false
        }

        if other.selector != selector {
            return false
        }

        if other.attributedName != attributedName {
            return false
        }

        if other.image != image {
            if other.image?.pngData() != image?.pngData() {
                return false
            }
        }

        if #available(iOS 18.0, *) {
            if other.category != category {
                return false
            }
        }
        return true
    }
}
#endif
