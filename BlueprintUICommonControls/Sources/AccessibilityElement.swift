import BlueprintUI
import UIKit

public struct AccessibilityElement: Element {





    public var label: String?
    public var value: String?
    public var hint: String?
    public var identifier: String?
    public var traits: Set<Trait>
    public var accessibilityFrameSize: CGSize?
    public var accessibilityFrameCornerStyle: CornerStyle
    public var wrappedElement: Element

    /// Used to provide custom behaviour when activated by voiceover. This will override the default behavior of issuing a tap event at the accessibility activation point.
    /// See [Accessibility Activate Documentation](https://developer.apple.com/documentation/objectivec/nsobject/1615165-accessibilityactivate) for further information.
    public var accessibilityActivate: (() -> Bool)? = nil

    /// An array containing one or more `CustomAction`s, defining additional supported actions. Assistive technologies, such as VoiceOver, will display your custom actions to the user at appropriate times.
    public var customActions: [CustomAction] = []

    /// An array containing one or more `CustomContent`s, defining additional content associated with the element. Assistive technologies, such as VoiceOver, will announce your custom content to the user at appropriate times.
    public var customContent: [CustomContent] = []


    public init(
        label: String?,
        value: String?,
        traits: Set<AccessibilityElement.Trait>,
        hint: String? = nil,
        identifier: String? = nil,
        accessibilityFrameSize: CGSize? = nil,
        accessibilityFrameCornerStyle: CornerStyle = .square,
        customActions: [AccessibilityElement.CustomAction] = [],
        customContent: [AccessibilityElement.CustomContent] = [],
        wrapping element: Element,
        configure: (inout Self) -> Void = { _ in }
    ) {
        self.label = label
        self.value = value
        self.traits = traits
        self.hint = hint
        self.identifier = identifier
        self.accessibilityFrameSize = accessibilityFrameSize
        self.accessibilityFrameCornerStyle = accessibilityFrameCornerStyle
        self.customActions = customActions
        self.customContent = customContent
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
            config[\.accessibilityFrameCornerStyle] = accessibilityFrameCornerStyle
            config[\.activate] = accessibilityActivate
            config[\.accessibilityCustomActions] = customActions.map { action in
                UIAccessibilityCustomAction(name: action.name, image: action.image) { _ in action.onActivation() }
            }
            config[\.accessibilityCustomContent] = customContent.map { $0.axCustomContent }


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

    private final class AccessibilityView: UIView, AXCustomContentProvider {
        var accessibilityFrameSize: CGSize?
        var accessibilityFrameCornerStyle: CornerStyle = .square
        var accessibilityCustomContent: [AXCustomContent]! = [] // The exclamation `!` is in the protodol definition and required.

        var increment: (() -> Void)?
        var decrement: (() -> Void)?
        var activate: (() -> Bool)?

        override var accessibilityFrame: CGRect {
            get {
                guard let accessibilityFrameSize = accessibilityFrameSize else {
                    return UIAccessibility.convertToScreenCoordinates(
                        bounds,
                        in: self
                    )
                }

                let adjustedFrame = bounds.insetBy(
                    dx: bounds.width - accessibilityFrameSize.width,
                    dy: bounds.height - accessibilityFrameSize.height
                )

                return UIAccessibility.convertToScreenCoordinates(
                    adjustedFrame,
                    in: self
                )
            }

            set {
                fatalError("accessibilityFrame is not settable on AccessibilityView")
            }
        }

        override var accessibilityPath: UIBezierPath? {
            get {
                guard accessibilityFrameCornerStyle != .square else {
                    return nil
                }

                return UIBezierPath(
                    rect: accessibilityFrame,
                    corners: accessibilityFrameCornerStyle
                )
            }

            set {
                fatalError("accessibilityPath is not settable on AccessibilityView")
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
        accessibilityFrameSize: CGSize? = nil,
        accessibilityFrameCornerStyle: CornerStyle = .square,
        customActions: [AccessibilityElement.CustomAction] = [],
        customContent: [AccessibilityElement.CustomContent] = []
    ) -> AccessibilityElement {
        AccessibilityElement(
            label: label,
            value: value,
            traits: traits,
            hint: hint,
            identifier: identifier,
            accessibilityFrameSize: accessibilityFrameSize,
            accessibilityFrameCornerStyle: accessibilityFrameCornerStyle,
            customActions: customActions,
            customContent: customContent,
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
    public func deprecated_accessibility(
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



extension AccessibilityElement {
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


extension AccessibilityElement {
    /// Used to provide additional functionality to assistive technologies beyond your accessible UI.
    public struct CustomAction: Equatable, Hashable {
        public typealias OnActivation = () -> Bool

        /// A localized name that discribes the action.
        public var name: String
        /// An image representing the action to be shown with some assistive technologies such as Switch Control.
        public var image: UIImage?
        /// A Callback for when the action is activated. This should return a `bool` indicating success or failure of the action.
        public var onActivation: OnActivation

        public init(name: String, image: UIImage? = nil, onActivation: @escaping OnActivation) {
            self.name = name
            self.image = image
            self.onActivation = onActivation
        }

        public static func == (lhs: AccessibilityElement.CustomAction, rhs: AccessibilityElement.CustomAction) -> Bool {
            // Disregard onActivation for equatablity pruposes.
            lhs.name == rhs.name && lhs.image == rhs.image
        }

        public func hash(into hasher: inout Hasher) {
            // Disregard onActivation for hash pruposes.
            hasher.combine(name)
            hasher.combine(image)
        }
    }
}

extension AccessibilityElement {
    public struct CustomContent {
        /// The importance of the content.
        public enum Importance: Equatable {
            /// By default custom content is available through the rotor.
            case `default`
            /// In addtion to being available through the rotor, high importance content will announced in the main VoiceOver utterance.
            /// High Importance content is announced follllowing the `accessibilityValue` but preceding any `accessibilityHint`.
            case high
        }

        public var label: String
        public var value: String?
        public var importance: Importance

        public init(label: String, value: String? = nil, importance: Importance = .default) {
            self.label = label
            self.value = value
            self.importance = importance
        }

        public var axCustomContent: AXCustomContent {
            let importance: AXCustomContent.Importance
            switch self.importance {
            case .high:
                importance = .high
            case .default:
                importance = .default
            }
            return .init(label: label, value: value, importance: importance)
        }
    }
}


extension AXCustomContent {
    public convenience init(_ content: AccessibilityElement.CustomContent) {
        self.init(label: content.label, value: content.value, importance: content.importance == .high ? .high : .default)
    }

    public convenience init(label: String, value: String?, importance: AXCustomContent.Importance = .default) {
        self.init(label: label, value: value ?? "")
        self.importance = importance
    }
}

