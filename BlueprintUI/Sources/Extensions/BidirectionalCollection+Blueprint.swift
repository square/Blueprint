import UIKit

extension BidirectionalCollection where Element: Equatable, Element: NSObjectProtocol {
    private func itemSearch(_ predicate: UIAccessibilityCustomRotorSearchPredicate) -> UIAccessibilityCustomRotorItemResult? {
        guard let first else { return nil }
        guard let currentItem = predicate.currentItem.targetElement as? Element,
              let currentIndex = firstIndex(of: currentItem),
              predicate.searchDirection == .previous || predicate.searchDirection == .next
        else {
            return UIAccessibilityCustomRotorItemResult(targetElement: first, targetRange: nil)
        }
        let newIndex = (predicate.searchDirection == .next ? index(after: currentIndex) : index(before: currentIndex))
            .clamped(min: startIndex, max: index(before: endIndex))
        return .init(targetElement: self[newIndex], targetRange: nil)
    }

    /// Returns a UIAccessibilityCustomRotor with the provided system type which cycles through the contained elements.
    public func accessibilityRotor(systemType type: UIAccessibilityCustomRotor.SystemRotorType) -> UIAccessibilityCustomRotor {
        UIAccessibilityCustomRotor(systemType: type) { itemSearch($0) }
    }
}

// MARK: Misc. Internal
extension Comparable {
    fileprivate func clamped(min: Self, max: Self) -> Self {
        Swift.max(Swift.min(self, max), min)
    }
}
