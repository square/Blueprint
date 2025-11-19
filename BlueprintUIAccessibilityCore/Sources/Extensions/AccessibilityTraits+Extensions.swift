import BlueprintUI
import UIKit

extension Accessibility.Trait {
    // Note that .adjustable trait has empty actions. Do not apply these traits to an actual element.
    // This is marked internal so that it is accessible by tests but should be considered fileprivate and used with caution.
    internal static let allTraits: [Accessibility.Trait] =
        [
            .button,
            .link,
            .header,
            .searchField,
            .image,
            .selected,
            .playsSound,
            .keyboardKey,
            .staticText,
            .summaryElement,
            .notEnabled,
            .updatesFrequently,
            .startsMediaSession,
            .adjustable({}, {}),
            .allowsDirectInteraction,
            .causesPageTurn,
            .tabBar,
        ]

    public var isAdjustable: Bool {
        switch self {
        case .adjustable:
            true
        default:
            false
        }
    }
}

extension UIAccessibilityTraits {
    internal var blueprintTraits: Set<Accessibility.Trait> {
        Accessibility.Trait.allTraits
            .lazy
            .filter { self.contains(UIAccessibilityTraits(with: [$0])) }
            .reduce(into: Set<Accessibility.Trait>()) { $0.insert($1) }
    }
}
