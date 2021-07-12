import BlueprintUI
import UIKit

public struct AccessibilityElement: Element, KeyPathComparableElement {

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
        self.wrappedElement = element
    }

    private var accessibilityTraits: UIAccessibilityTraits {
        var traits: UIAccessibilityTraits = .none

        for trait in self.traits {
            switch trait {
            case .button:
                traits.formUnion(.button)
            case .link:
                traits.formUnion(.link)
            case .header:
                traits.formUnion(.header)
            case .searchField:
                traits.formUnion(.searchField)
            case .image:
                traits.formUnion(.image)
            case .selected:
                traits.formUnion(.selected)
            case .playsSound:
                traits.formUnion(.playsSound)
            case .keyboardKey:
                traits.formUnion(.keyboardKey)
            case .staticText:
                traits.formUnion(.staticText)
            case .summaryElement:
                traits.formUnion(.summaryElement)
            case .notEnabled:
                traits.formUnion(.notEnabled)
            case .updatesFrequently:
                traits.formUnion(.updatesFrequently)
            case .startsMediaSession:
                traits.formUnion(.startsMediaSession)
            case .adjustable:
                traits.formUnion(.adjustable)
            case .allowsDirectInteraction:
                traits.formUnion(.allowsDirectInteraction)
            case .causesPageTurn:
                traits.formUnion(.causesPageTurn)
            case .tabBar:
                traits.formUnion(.tabBar)
            }
        }

        return traits
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
    
    public static let isEquivalent = IsEquivalent<AccessibilityElement> {
        $0.add(\.accessibilityFrameSize)
        $0.add(\.wrappedElement)
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


public extension Element {

    /// Wraps the element to provide the passed accessibility
    /// options to the accessibility system.
    func accessibility(
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
