import BlueprintUI
import UIKit

public struct AccessibilityElement: Element {

    public enum Trait: Hashable {
        case button
        case link
        case header
        case searchField
        case image
        case selected
        case playsSound
        case keyboardKey
        case staticText
        case summaryElement
        case notEnabled
        case updatesFrequently
        case startsMediaSession
        case adjustable
        case allowsDirectInteraction
        case causesPageTurn
        case tabBar
    }

    public var label: String?
    public var value: String?
    public var hint: String?
    public var identifier: String?
    public var traits: Set<Trait>
    public var accessibilityFrameSize: CGSize?
    public var wrappedElement: Element

    public init(
        label: String?,
        value: String?,
        traits: Set<AccessibilityElement.Trait>,
        hint: String? = nil,
        identifier: String? = nil,
        accessibilityFrameSize: CGSize? = nil,
        wrapping element: Element
    ) {
        self.label = label
        self.value = value
        self.traits = traits
        self.hint = hint
        self.identifier = identifier
        self.accessibilityFrameSize = accessibilityFrameSize
        wrappedElement = element
    }

    @available(
        *,
        deprecated,
        renamed: "init(label:value:traits:hint:identifier:accessibilityFrameSize:wrapping:)"
    )
    public init(
        label: String? = nil,
        value: String? = nil,
        hint: String? = nil,
        identifier: String? = nil,
        traits: Set<Trait> = [],
        accessibilityFrameSize: CGSize? = nil,
        wrapping element: Element
    ) {
        self.init(
            label: label,
            value: value,
            traits: traits,
            hint: hint,
            identifier: identifier,
            accessibilityFrameSize: accessibilityFrameSize,
            wrapping: element
        )
    }

    private var accessibilityTraits: UIAccessibilityTraits {
        UIAccessibilityTraits(with: traits)
    }

    public var content: ElementContent {
        ElementContent(child: wrappedElement)
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        AccessibilityView.describe { config in
            config[\.accessibilityLabel] = label
            config[\.accessibilityValue] = value
            config[\.accessibilityHint] = hint
            config[\.accessibilityIdentifier] = identifier
            config[\.accessibilityTraits] = accessibilityTraits
            config[\.isAccessibilityElement] = true
            config[\.accessibilityFrameSize] = accessibilityFrameSize
        }
    }

    private final class AccessibilityView: UIView {

        var accessibilityFrameSize: CGSize?

        override var accessibilityFrame: CGRect {
            get {
                guard let accessibilityFrameSize = accessibilityFrameSize else {
                    return UIAccessibility.convertToScreenCoordinates(bounds, in: self)
                }

                let adjustedFrame = bounds.insetBy(
                    dx: bounds.width - accessibilityFrameSize.width,
                    dy: bounds.height - accessibilityFrameSize.height
                )

                return UIAccessibility.convertToScreenCoordinates(adjustedFrame, in: self)
            }
            set {
                fatalError("accessibilityFrame is not settable on AccessibilityView")
            }
        }
    }
}


extension Element {


    /// Wraps the receiver in an accessibility element with the provided values.
    ///
    /// - Important: ⚠️ This overrides the accessibility of the contained element and all of its children ⚠️
    ///
    /// - SeeAlso: ``accessibilityElement``
    @available(
        *,
        deprecated,
        renamed: "accessibilityElement(label:value:traits:hint:identifier:accessibilityFrameSize:)"
    )
    public func accessibility(
        label: String? = nil,
        value: String? = nil,
        hint: String? = nil,
        identifier: String? = nil,
        traits: Set<AccessibilityElement.Trait> = [],
        accessibilityFrameSize: CGSize? = nil
    ) -> AccessibilityElement {
        accessibilityElement(
            label: label,
            value: value,
            traits: traits,
            hint: hint,
            identifier: identifier,
            accessibilityFrameSize: accessibilityFrameSize
        )
    }

    /// Wraps the receiver in an accessibility element with the provided values.
    ///
    /// Providing a `nil` value for any of these parameters will result in no resolved value for that accessibility
    /// parameter—it does not inherit parameters from the wrapped element's accessibility configuration.
    ///
    /// - Important: ⚠️ This overrides the accessibility of the contained element and all of its children ⚠️
    public func accessibilityElement(
        label: String?,
        value: String?,
        traits: Set<AccessibilityElement.Trait>,
        hint: String? = nil,
        identifier: String? = nil,
        accessibilityFrameSize: CGSize? = nil
    ) -> AccessibilityElement {
        AccessibilityElement(
            label: label,
            value: value,
            traits: traits,
            hint: hint,
            identifier: identifier,
            accessibilityFrameSize: accessibilityFrameSize,
            wrapping: self
        )
    }
}


extension UIAccessibilityTraits {

    public init(with set: Set<AccessibilityElement.Trait>) {
        self.init(rawValue: UIAccessibilityTraits.none.rawValue)
        for trait in set {
            switch trait {
            case .button:
                formUnion(.button)
            case .link:
                formUnion(.link)
            case .header:
                formUnion(.header)
            case .searchField:
                formUnion(.searchField)
            case .image:
                formUnion(.image)
            case .selected:
                formUnion(.selected)
            case .playsSound:
                formUnion(.playsSound)
            case .keyboardKey:
                formUnion(.keyboardKey)
            case .staticText:
                formUnion(.staticText)
            case .summaryElement:
                formUnion(.summaryElement)
            case .notEnabled:
                formUnion(.notEnabled)
            case .updatesFrequently:
                formUnion(.updatesFrequently)
            case .startsMediaSession:
                formUnion(.startsMediaSession)
            case .adjustable:
                formUnion(.adjustable)
            case .allowsDirectInteraction:
                formUnion(.allowsDirectInteraction)
            case .causesPageTurn:
                formUnion(.causesPageTurn)
            case .tabBar:
                formUnion(.tabBar)
            }
        }
    }
}
