import BlueprintUI
import UIKit

public struct AccessibilityElement: Element {

    public enum Trait {
        /// Used in conjunction with UIAccessibilityTrait.adjustable, these will be called to allow accessible adjustment of a value, for example in a slider or stepper control.
        /// See [Accessibility Increment Documentation](https://developer.apple.com/documentation/objectivec/nsobject/1615076-accessibilityincrement) for further information.
        public typealias IncrementAction = () -> Void

        /// Used in conjunction with UIAccessibilityTrait.adjustable, these will be called to allow accessible adjustment of a value, for example in a slider or stepper control.
        /// See [Accessibility Decrement Documentation](https://developer.apple.com/documentation/objectivec/nsobject/1615169-accessibilitydecrement) for further information.
        public typealias DecrementAction = () -> Void

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
        case adjustable(IncrementAction, DecrementAction)
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

    /// Used to provide custom behaviour when activated by voiceover. This will override the default behavior of issuing a tap event at the accessibility activation point.
    /// See [Accessibility Activate Documentation](https://developer.apple.com/documentation/objectivec/nsobject/1615165-accessibilityactivate) for further information.
    public var accessibilityActivate: (() -> Bool)? = nil

    public init(
        label: String?,
        value: String?,
        traits: Set<AccessibilityElement.Trait>,
        hint: String? = nil,
        identifier: String? = nil,
        accessibilityFrameSize: CGSize? = nil,
        wrapping element: Element,
        configure: (inout Self) -> Void = { _ in }
    ) {
        self.label = label
        self.value = value
        self.traits = traits
        self.hint = hint
        self.identifier = identifier
        self.accessibilityFrameSize = accessibilityFrameSize
        wrappedElement = element
        configure(&self)
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
            config[\.activate] = accessibilityActivate

            if let adjustable = traits.first(where: { $0 == .adjustable({}, {}) }),
               case let .adjustable(incrementAction, decrementAction) = adjustable
            {
                config[\.increment] = incrementAction
                config[\.decrement] = decrementAction
            } else {
                config[\.increment] = nil
                config[\.decrement] = nil
            }
        }
    }

    private final class AccessibilityView: UIView {

        var accessibilityFrameSize: CGSize?

        var increment: (() -> Void)?
        var decrement: (() -> Void)?
        var activate: (() -> Bool)?

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

        override func accessibilityIncrement() {
            increment?()
        }

        override func accessibilityDecrement() {
            decrement?()
        }

        override func accessibilityActivate() -> Bool {
            guard let activate = activate else {
                return super.accessibilityActivate()
            }
            return activate()
        }

    }
}

extension AccessibilityElement.Trait: Hashable, Equatable {
    /// This conformance to `Hashable` is provided to allow traits to be included in a `Set`.
    /// - Important: ⚠️ This implementation does not take equality of associated values on `.adjustable` into account.  ⚠️
    private var internalValue: Int {
        switch self {
        case .button: return 0
        case .link: return 1
        case .header: return 2
        case .searchField: return 3
        case .image: return 4
        case .selected: return 5
        case .playsSound: return 6
        case .keyboardKey: return 7
        case .staticText: return 8
        case .summaryElement: return 9
        case .notEnabled: return 10
        case .updatesFrequently: return 11
        case .startsMediaSession: return 12
        case .adjustable: return 13
        case .allowsDirectInteraction: return 14
        case .causesPageTurn: return 15
        case .tabBar: return 16
        }
    }

    public static func == (lhs: AccessibilityElement.Trait, rhs: AccessibilityElement.Trait) -> Bool {
        lhs.internalValue == rhs.internalValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(internalValue)
    }
}

extension Element {

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

