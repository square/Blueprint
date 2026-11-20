import Accessibility
import BlueprintUI
import BlueprintUIAccessibilityCore
import UIKit


/// ### Use `AccessibilityCombine` to automatically combine child accessibility elements:
/// ```swift
/// struct CustomRow: Element {
///     var content: ElementContent {
///         Row {
///             Image(image: profileImage)
///             Column {
///                 Label(text: userName)
///                 Label(text: userStatus)
///             }
///             Button("Follow") { followUser() }
///         }
///         .accessibilityCombine()
///         // Automatically combines: "Profile image, John Doe, Online, Follow"
///         // Button functionality preserved as custom action
///     }
/// }
/// ```
///
/// ### Custom Filtering and Sorting
///
/// ```swift
/// struct SmartCombinedElement: Element {
///     var content: ElementContent {
///         Column {
///             Label(text: "Header").accessibilityTraits(add: [.header])
///             Label(text: "Content")
///             Button("Action") { /* action */ }
///         }
///         .accessibilityCombine(
///             customFilter: { element in
///                 // Only include elements with accessibility content
///                 return element.hasAccessibilityRepresentation
///             },
///             customSorting: { element1, element2 in
///                 // Headers come first
///                 let element1IsHeader = element1.accessibilityTraits.contains(.header)
///                 let element2IsHeader = element2.accessibilityTraits.contains(.header)
///                 return element1IsHeader && !element2IsHeader
///             }
///         )
///     }
/// }
/// ```
public struct AccessibilityCombine: Element {

    /// The wrapped element
    public var wrappedElement: Element

    /// A filter closure that will be applied to the discovered child elements, allowing for conditional inclusion.
    /// Return `true` if the element should be included in the derived accessibility representation.
    public var customFilter: AccessibilityComposition.Filter?

    /// A sorting closure that will be applied to the discovered child elements, allowing for custom sort order.
    /// If no custom sorting is provided, elements will be using by their accessibility frame with a  `Leading -> Trailing, Top -> Bottom` heuristic.
    public var customSorting: AccessibilityComposition.Sorting?

    /// After generating the combined accessibility representation, if this flag is `true`, the element will
    /// not be accessible unless it has a non-nil and non-empty `accessibilityLabel`, `accessibilityValue`, or `accessibilityHint`.
    public var blockWhenNotAccessible: Bool

    public init(
        wrapping element: @escaping () -> Element,
        customFilter: AccessibilityComposition.Filter? = nil,
        customSorting: AccessibilityComposition.Sorting? = nil,
        blockWhenNotAccessible: Bool = true
    ) {
        wrappedElement = element()
        self.customFilter = customFilter
        self.customSorting = customSorting
        self.blockWhenNotAccessible = blockWhenNotAccessible
    }


    public var content: ElementContent {
        ElementContent(child: wrappedElement)
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        AccessibilityComposition.CombinableView.describe { config in
            config[\.needsAccessibilityUpdate] = true
            config[\.layoutDirection] = context.environment.layoutDirection
            config[\.customSorting] = customSorting
            config[\.customFilter] = customFilter
            config[\.blockWhenNotAccessible] = blockWhenNotAccessible
        }
    }
}

extension Element {
    /// Wraps the receiver in an accessibility element with values derived by combining the contained child elements.
    ///
    /// - Important: ⚠️ This completely overrides the accessibility of the contained element and all of its children ⚠️
    /// - Parameters:
    ///   - customFilter: A filter for conditionally combining child elements.
    ///   - customSorting: A closure for sorting child elements into a custom ordering.
    ///   - blockWhenNotAccessible: A flag for blocking accessibility if there is no combined representation.
    /// - Returns: A wrapped `Element` with a combined accessibility representation.
    public func accessibilityCombine(
        customFilter: AccessibilityComposition.Filter? = nil,
        customSorting: AccessibilityComposition.Sorting? = nil,
        blockWhenNotAccessible: Bool = true
    ) -> AccessibilityCombine {
        AccessibilityCombine(
            wrapping: { self },
            customFilter: customFilter,
            customSorting: customSorting,
            blockWhenNotAccessible: blockWhenNotAccessible
        )
    }
}
