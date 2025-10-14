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
        var set = Set<Accessibility.Trait>()
        for trait in Accessibility.Trait.allTraits {
            if contains(UIAccessibilityTraits(with: [trait])) {
                set.insert(trait)
            }
        }
        return set
    }
}
