import BlueprintUI
import UIKit


public struct AccessibilityElement: Element {
    public typealias Trait = Accessibility.Trait
    public typealias CustomAction = Accessibility.CustomAction
    public typealias CustomContent = Accessibility.CustomContent

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

    /// An array of localized labels the user provides to refer to the accessibility element.
    /// This is primarily used for Voice control, an element that contains descriptive information in its accessibilityLabel can return a more concise label. The primary label is first in the array, optionally followed by alternative labels in descending order of importance.
    public var userInputLabels: [String] = []

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
        userInputLabels: [String] = [],
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
        self.userInputLabels = userInputLabels
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
            config.apply { element in
                element.accessibilityLabel = label
                element.accessibilityValue = value
                element.accessibilityHint = hint
                element.accessibilityIdentifier = identifier
                element.accessibilityTraits = accessibilityTraits
                element.isAccessibilityElement = true
                element.accessibilityFrameSize = accessibilityFrameSize
                element.accessibilityFrameCornerStyle = accessibilityFrameCornerStyle
                element.activate = accessibilityActivate
                element.accessibilityCustomActions = customActions.map { action in
                    UIAccessibilityCustomAction(name: action.name, image: action.image) { _ in action.onActivation() }
                }
                element.accessibilityCustomContent = customContent.map { $0.axCustomContent }
                element.accessibilityUserInputLabels = userInputLabels

                if let adjustable = traits.first(where: { $0 == .adjustable({}, {}) }),
                   case let .adjustable(incrementAction, decrementAction) = adjustable
                {
                    element.increment = incrementAction
                    element.decrement = decrementAction
                } else {
                    element.increment = nil
                    element.decrement = nil
                }
            }
        }
    }

    private final class AccessibilityView: UIView, AXCustomContentProvider {
        var accessibilityFrameSize: CGSize?
        var accessibilityFrameCornerStyle: CornerStyle = .square
        var accessibilityCustomContent: [AXCustomContent]! = [] // The exclamation `!` is in the protocol definition and required.

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
        customContent: [AccessibilityElement.CustomContent] = [],
        userInputLabels: [String] = []
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
            userInputLabels: userInputLabels,
            wrapping: self
        )
    }
}

extension AccessibilityElement {
    public static func frameSort(direction: Environment.LayoutDirection) -> (NSObject, NSObject) -> Bool {
        {
            let first = $0.accessibilityFrame
            let second = $1.accessibilityFrame

            // Derived through experimentation, this mimics the default sorting for UIKit.
            // If frames differ by more than 8 points the top most element is preferred.
            let verticalThreshold = 8.0
            let verticalDelta = abs(first.minY - second.minY)
            if verticalDelta > verticalThreshold {
                return first.minY < second.minY
            }

            // Prefer the leading element.
            switch direction {
            case .leftToRight:
                return first.minX < second.minX

            case .rightToLeft:
                return first.maxX > second.maxX
            }
        }
    }
}
