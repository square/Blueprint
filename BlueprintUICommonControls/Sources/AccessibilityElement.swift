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
        label: String? = nil,
        value: String? = nil,
        hint: String? = nil,
        identifier: String? = nil,
        traits: Set<Trait> = [],
        accessibilityFrameSize: CGSize? = nil,
        wrapping element: Element
    ) {
        self.label = label
        self.value = value
        self.hint = hint
        self.identifier = identifier
        self.traits = traits
        self.accessibilityFrameSize = accessibilityFrameSize
        wrappedElement = element
    }

    private var accessibilityTraits: UIAccessibilityTraits {
        return UIAccessibilityTraits(withSet: traits)
    }

    public var content: ElementContent {
        return ElementContent(child: wrappedElement)
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        return AccessibilityView.describe { config in
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

    /// Wraps the element to provide the passed accessibility
    /// options to the accessibility system.
    public func accessibility(
        label: String? = nil,
        value: String? = nil,
        hint: String? = nil,
        identifier: String? = nil,
        traits: Set<AccessibilityElement.Trait> = [],
        accessibilityFrameSize: CGSize? = nil
    ) -> AccessibilityElement {
        AccessibilityElement(
            label: label,
            value: value,
            hint: hint,
            identifier: identifier,
            traits: traits,
            accessibilityFrameSize: accessibilityFrameSize,
            wrapping: self
        )
    }
}


extension UIAccessibilityTraits {

    public init(withSet set: Set<AccessibilityElement.Trait>) {
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
