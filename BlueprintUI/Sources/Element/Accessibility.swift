import UIKit

public enum Accessibility {} //  Namespace for collecting Blueprint models of UIKit Accessibility features.

// MARK: - Accessibility Traits
extension Accessibility {

    /// Constants that describe how an accessibility element behaves.
    /// Set these traits to tell an assistive app how an accessibility element behaves or how to treat it.
    /// See [UIAccessibilityTraits](https://developer.apple.com/documentation/uikit/uiaccessibilitytraits) for further information.
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
        case backButton
        case toggleButton
    }
}

extension Accessibility.Trait: Hashable, Equatable {
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
        case .backButton: return 17
        case .toggleButton: return 18
        }
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.internalValue == rhs.internalValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(internalValue)
    }
}

extension UIAccessibilityTraits {

    public init(with set: Set<Accessibility.Trait>) {
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
            case .backButton:
                formUnion(.backButton)
            case .toggleButton:
                formUnion(._toggleButton)
            }
        }
    }
}

// MARK: - Custom Actions
extension Accessibility {
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

        public static func == (lhs: Self, rhs: Self) -> Bool {
            // Disregard onActivation for equatablity purposes.
            lhs.name == rhs.name && lhs.image == rhs.image
        }

        public func hash(into hasher: inout Hasher) {
            // Disregard onActivation for hash purposes.
            hasher.combine(name)
            hasher.combine(image)
        }
    }
}


// MARK: - Custom Content
extension Accessibility {
    public struct CustomContent: Equatable, Hashable {
        /// The importance of the content.
        public enum Importance: Equatable {
            /// By default custom content is available through the rotor.
            case `default`
            /// In addition to being available through the rotor, high importance content will announced in the main VoiceOver utterance.
            /// High Importance content is announced following the `accessibilityValue` but preceding any `accessibilityHint`.
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
    public convenience init(_ content: Accessibility.CustomContent) {
        self.init(label: content.label, value: content.value, importance: content.importance == .high ? .high : .default)
    }

    public convenience init(label: String, value: String?, importance: AXCustomContent.Importance = .default) {
        self.init(label: label, value: value ?? "")
        self.importance = importance
    }
}

extension Accessibility {
    public static func frameSort(
        direction: Environment.LayoutDirection,
        root: UIView,
        userInterfaceIdiom: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom
    ) -> (NSObject, NSObject) -> Bool {
        {
            let first = root.convert($0.accessibilityFrame, from: nil)
            let second = root.convert($1.accessibilityFrame, from: nil)

            // Horizontal sorting logic - reusable for both center-aligned and fallback cases
            let sortHorizontally = {
                switch direction {
                case .leftToRight:
                    return first.minX < second.minX
                case .rightToLeft:
                    return first.maxX > second.maxX
                }
            }

            // Check if elements are vertically aligned along their central axis first.
            // While this check deviates from VoiceOver's behavior for UIKit, it covers one frequent
            // use case of Blueprint Row where it contains a number of elements with their
            // verticalAlignment set to .center. Since there's no view representation for Row,
            // checking for midY alignment is a reasonable heuristic in its absence.
            let centerYTolerance: CGFloat = 1.0
            let centerYDelta = abs(first.midY - second.midY)

            if centerYDelta <= centerYTolerance {
                // Elements are center-aligned, sort horizontally.
                return sortHorizontally()
            }

            // Derived through experimentation, this mimics the default sorting for UIKit.
            // If frames differ by more than 8 points the top most element is preferred.
            let minYTolerance = userInterfaceIdiom == .phone ? 8.0 : 13.0
            let minYDelta = abs(first.minY - second.minY)
            if minYDelta <= minYTolerance {
                // Elements are within vertical tolerance, sort horizontally.
                return sortHorizontally()
            }

            return first.minY < second.minY
        }
    }
}
