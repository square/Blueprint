import Foundation

internal enum LocalizedStrings {
    internal enum Accessibility {

        public static let errorTitle = NSLocalizedString(
            "accessibility_error_label",
            bundle: .module,
            value: "Error",
            comment: "A label for accessibility custom content that indicates that an associated string is an error message."
        )

        static let increment = NSLocalizedString(
            "Increment",
            bundle: .module,
            comment: "Accessibility action to increment a value"
        )

        static let decrement = NSLocalizedString(
            "Decrement",
            bundle: .module,
            comment: "Accessibility action to decrement a value"
        )

        internal enum ToggleButton {
            static let offValue = NSLocalizedString(
                "Off",
                bundle: .module,
                comment: "Accessibility value for a toggle button in the off state"
            )

            static let onValue = NSLocalizedString(
                "On",
                bundle: .module,
                comment: "Accessibility value for a toggle button in the on state"
            )

            static let mixedValue = NSLocalizedString(
                "Mixed",
                bundle: .module,
                comment: "Accessibility value for a toggle button in a mixed state"
            )
        }
    }
}

