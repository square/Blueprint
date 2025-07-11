import UIKit

extension BidirectionalCollection where Element: Equatable & NSObjectProtocol {

    /// Returns a UIAccessibilityCustomRotor with the provided system type which cycles through the contained elements.
    public func accessibilityRotor(systemType type: UIAccessibilityCustomRotor.SystemRotorType) -> UIAccessibilityCustomRotor {
        UIAccessibilityCustomRotor(systemType: type) { [weak self] in
            self?.itemSearch($0)
        }
    }

    private func itemSearch(_ predicate: UIAccessibilityCustomRotorSearchPredicate) -> UIAccessibilityCustomRotorItemResult? {
        guard let first else { return nil }
        guard let currentItem = predicate.currentItem.targetElement as? Element,
              let currentIndex = firstIndex(of: currentItem),
              predicate.searchDirection == .previous || predicate.searchDirection == .next
        else {
            return .init(targetElement: first, targetRange: nil)
        }
        let newIndex = (predicate.searchDirection == .next ? index(after: currentIndex) : index(before: currentIndex))
        guard newIndex >= startIndex, newIndex < endIndex else { return nil }
        return .init(targetElement: self[newIndex], targetRange: nil)
    }
}
