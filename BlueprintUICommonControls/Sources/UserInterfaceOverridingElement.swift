import BlueprintUI
import UIKit

/// An element that allows overriding the user interface style (light/dark mode) for its wrapped content.
///
/// Use this element to force a specific appearance for a portion of your UI, regardless of the system-wide
/// settings. This can be useful when you need to ensure certain UI elements maintain a consistent appearance
/// across different user interface styles.
///
/// Example:
/// ```swift
/// let content = Label(text: "Hello, World!")
/// let forcedLightMode = UserInterfaceOverridingElement(
///     userInterfaceStyle: .light,
///     wrapping: content
/// )
/// ```
public struct UserInterfaceStyleOverridingElement: Element {

    /// The element being wrapped with the overridden interface style.
    public var wrappedElement: Element

    /// The user interface style to apply to the wrapped content.
    /// This can be `.light`, `.dark`, or `.unspecified`.
    public var userInterfaceStyle: UIUserInterfaceStyle

    /// Creates a new element that overrides the user interface style for its wrapped content.
    ///
    /// - Parameters:
    ///   - userInterfaceStyle: The desired interface style to apply (`.light`, `.dark`, or `.unspecified`).
    ///   - wrapping: The content whose interface style should be overridden.
    public init(
        userInterfaceStyle: UIUserInterfaceStyle,
        wrapping content: () -> (Element)
    ) {
        self.userInterfaceStyle = userInterfaceStyle
        wrappedElement = content()
    }

    public var content: ElementContent {
        ElementContent(child: wrappedElement)
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        UIView.describe { config in
            config[\.overrideUserInterfaceStyle] = userInterfaceStyle
        }
    }
}

extension Element {
    /// Wraps this element in a `UserInterfaceStyleOverridingElement` to override its interface style.
    ///
    /// This method provides a convenient way to override the user interface style (light/dark mode)
    /// for any element.
    ///
    /// Example:
    /// ```swift
    /// Label(text: "Always Light Mode")
    ///   .overrideUserInterfaceStyle(.light)
    /// ```
    ///
    /// - Parameter override: The desired interface style to apply. Defaults to `.unspecified`.
    /// - Returns: A new element wrapped with the specified interface style override.
    public func overrideUserInterfaceStyle(
        _ override: UIUserInterfaceStyle = .unspecified
    ) -> UserInterfaceStyleOverridingElement {
        UserInterfaceStyleOverridingElement(userInterfaceStyle: override) {
            self
        }
    }
}
