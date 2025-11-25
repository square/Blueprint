import Accessibility
import BlueprintUI
import BlueprintUIAccessibilityCore
import BlueprintUICommonControls
import UIKit


extension Element {

    /// Wraps the receiver in an accessibility element with values derived by combining the contained child elements, using the provided values as an override.
    /// Nil values will be inherited from the combined accessibility of the contained element(s).
    public func accessibility(
        label: String? = nil,
        value: String? = nil,
        hint: String? = nil,
        traits: Set<Accessibility.Trait>? = nil,
        identifier: String? = nil
    ) -> Element {
        AccessibilitySetter(
            wrapping: { self },
            label: label,
            value: value,
            hint: hint,
            identifier: identifier,
            accessibilityTraits: traits
        )
    }

    /// Wraps the receiver in an accessibility.element with the provided accessibility traits added.
    /// All other accessibility values will be inherited from the combined accessibility of the contained element(s).
    public func accessibilityTraits(add: Set<Accessibility.Trait>) -> Element {
        AccessibilityTraitsAdjust(wrapping: { self }, add: add)
    }

    /// Wraps the receiver in an accessibility.element with the provided accessibility traits removed.
    /// All other accessibility values will be inherited from the combined accessibility of the contained element(s).
    public func accessibilityTraits(remove: Set<Accessibility.Trait>) -> Element {
        AccessibilityTraitsAdjust(wrapping: { self }, remove: remove)
    }
}

