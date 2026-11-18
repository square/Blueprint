import Accessibility
import BlueprintUI
import UIKit.UIAccessibilityIdentification


public struct AccessibilityComposition {
    public typealias Filter = (NSObject) -> Bool
    public typealias Sorting = (NSObject, NSObject) -> Bool

    /// Attributed content to use when composing an element with its siblings.
    public struct Text {
        public var label: NSAttributedString?
        public var value: NSAttributedString?
        public var hint: NSAttributedString?

        public init(label: NSAttributedString?, value: NSAttributedString?, hint: NSAttributedString?) {
            self.label = label
            self.value = value
            self.hint = hint
        }
    }

    /// Supplies the text a control contributes to a combined accessibility element.
    public protocol TextProviding {
        var accessibilityCompositionText: Text { get }
    }
}



extension AccessibilityComposition {
    public struct CompositeRepresentation {

        public struct Actions: Equatable {
            var activationAction: UIAccessibilityCustomAction?
            var increment: UIAccessibilityCustomAction?
            var decrement: UIAccessibilityCustomAction?
            var customActions: [UIAccessibilityCustomAction]?
        }

        public let elementsCount: Int

        public var attributedLabel: NSAttributedString?
        public var attributedValue: NSAttributedString?
        public var attributedHint: NSAttributedString?

        public var label: String? {
            get { attributedLabel?.string }
            set {
                if let newValue {
                    attributedLabel = .init(string: newValue)
                } else {
                    attributedLabel = nil
                }
            }
        }

        public var value: String? {
            get { attributedValue?.string }
            set {
                if let newValue {
                    attributedValue = .init(string: newValue)
                } else {
                    attributedValue = nil
                }
            }
        }

        public var hint: String? {
            get { attributedHint?.string }
            set {
                if let newValue {
                    attributedHint = .init(string: newValue)
                } else {
                    attributedHint = nil
                }
            }
        }

        public var identifier: String?
        public var traits: UIAccessibilityTraits = .none
        public var actions: Actions
        public var rotors: [UIAccessibilityCustomRotor]?
        public var customContent: [AXCustomContent]?
        public var interactiveChildren: [CompositeRepresentation]?
        public var activationPoint: CGPoint?
        public var invalidator: () -> Void

        var allActions: [UIAccessibilityCustomAction]? {
            let activation = [actions.activationAction].compactMap { $0 }
            let customActions = actions.customActions ?? []
            let adjustable = [actions.increment, actions.decrement].compactMap { $0 }
            return activation + customActions + adjustable
        }

        public init(_ elements: [NSObject], ignoreInteractive: Bool = true, invalidator: @escaping () -> Void) {
            elementsCount = elements.count
            var labels = [NSAttributedString?]()
            var values = [NSAttributedString?]()
            var hints = [NSAttributedString?]()
            var identifiers = [String]()
            var allRotors = [UIAccessibilityCustomRotor]()
            actions = Actions()
            var allContent = [AXCustomContent]()
            var allInteractiveChildren = [CompositeRepresentation]()
            self.invalidator = invalidator

            for element in elements {
                if element.isLikelyInteractive {
                    activationPoint = activationPoint ?? element.accessibilityActivationPoint
                    if ignoreInteractive {
                        allInteractiveChildren.append(.init(
                            [element],
                            ignoreInteractive: false,
                            invalidator: invalidator
                        ))
                        continue
                    }
                }

                let text = (element as? TextProviding)?.accessibilityCompositionText ?? Text(
                    label: element.accessibilityAttributedLabel ?? element.accessibilityLabel.map(NSAttributedString.init(string:)),
                    value: element.accessibilityAttributedValue ?? element.accessibilityValue.map(NSAttributedString.init(string:)),
                    hint: element.accessibilityAttributedHint ?? element.accessibilityHint.map(NSAttributedString.init(string:))
                )
                if let label = text.label {
                    labels.append(label)
                }

                if let value = text.value {
                    values.append(value)
                }

                if let hint = text.hint {
                    hints.append(hint)
                }

                if let identifier = element.extractedAccessibilityIdentifier {
                    identifiers.append(identifier)
                }

                traits.formUnion(element.accessibilityTraits)

                allRotors.append(contentsOf: element.accessibilityCustomRotors ?? [])
                if element.isLikelyInteractive, element.isAccessibilityEnabled {
                    actions.activationAction = element.accessibilityAction(didFire: { _, _ in invalidator() })
                    actions.increment = element.accessibilityIncrementDecrementActions?.increment
                    actions.decrement = element.accessibilityIncrementDecrementActions?.decrement
                }

                actions.customActions = actions.customActions + element.accessibilityCustomActions

                if let provider = element as? AXCustomContentProvider {
                    if #available(iOS 17, *),
                       // optional protocol var that returns an optional block that returns an optional array.
                       let implemented = provider.accessibilityCustomContentBlock,
                       let nonOptional = implemented,
                       let content = nonOptional()
                    {
                        allContent.append(contentsOf: content)
                    }
                    allContent.append(contentsOf: provider.accessibilityCustomContent ?? [])
                }
            }

            attributedLabel = labels.removingDuplicates.joinedAccessibilityText()
            attributedValue = values.removingDuplicates.joinedAccessibilityText()
            attributedHint = hints.removingDuplicates.joinedAccessibilityText()

            let identifier = identifiers
                .removingDuplicates
                .filter { !$0.isEmpty }
                .joined(separator: "-")
            self.identifier = identifier.isEmpty ? nil : identifier

            rotors = allRotors.isEmpty ? nil : allRotors
            customContent = allContent.isEmpty ? nil : allContent
            interactiveChildren = allInteractiveChildren.isEmpty ? nil : allInteractiveChildren
        }

        internal func merge(with other: AccessibilityComposition.CompositeRepresentation?) -> AccessibilityComposition.CompositeRepresentation {
            guard let other else { return self }
            var new = AccessibilityComposition.CompositeRepresentation([], invalidator: invalidator)
            new.attributedLabel = [attributedLabel, other.attributedLabel].joinedAccessibilityText()
            new.attributedValue = [attributedValue, other.attributedValue].joinedAccessibilityText()
            new.attributedHint = [attributedHint, other.attributedHint].joinedAccessibilityText()
            new.identifier = [identifier, other.identifier].joinedAccessibilityString()

            new.traits = traits.union(other.traits)

            new.actions = actions
            new.actions.customActions += other.allActions

            new.rotors = rotors + other.rotors
            new.interactiveChildren = interactiveChildren + other.interactiveChildren

            new.activationPoint = activationPoint ?? other.activationPoint

            return new
        }

        internal func override(with override: AccessibilityComposition.CompositeRepresentation?) -> AccessibilityComposition.CompositeRepresentation {
            guard let override else { return self }
            var new = AccessibilityComposition.CompositeRepresentation([], invalidator: invalidator)
            new.attributedLabel = override.attributedLabel ?? attributedLabel
            new.attributedValue = override.attributedValue ?? attributedValue
            new.attributedHint = override.attributedHint ?? attributedHint
            new.identifier = override.identifier ?? identifier

            new.traits = override.traits != .none ? override.traits : traits
            new.actions = (override.allActions?.isEmpty ?? false) ? actions : override.actions
            new.rotors = override.rotors ?? rotors
            new.interactiveChildren = override.interactiveChildren ?? interactiveChildren
            new.activationPoint = override.activationPoint ?? activationPoint
            return new
        }
    }
}

extension AccessibilityComposition.CompositeRepresentation: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        // invalidator ignored
        lhs.attributedLabel == rhs.attributedLabel &&
            lhs.attributedValue == rhs.attributedValue &&
            lhs.attributedHint == rhs.attributedHint &&
            lhs.identifier == rhs.identifier &&
            lhs.traits == rhs.traits &&
            lhs.actions == rhs.actions &&
            lhs.rotors == rhs.rotors &&
            lhs.customContent == rhs.customContent &&
            lhs.interactiveChildren == rhs.interactiveChildren &&
            lhs.activationPoint == rhs.activationPoint &&
            lhs.allActions == rhs.allActions
    }
}

extension AccessibilityComposition {

    // This type abstracts away the fact that we use UIAccessibilityCustomActions instead exposing basic swift closures for outside conforming types to work with.
    // Use computed var's over func's to preserve the nullability of our actions so that consumers know when to override their own values.
    public struct Interactions {
        /// A point that should be returned from within an `accessibilityActivationPoint()` override if present.
        public let activationPoint: CGPoint?

        /// A closure that should be called from within an `accessibilityActivate()` override if present.
        public let activate: (() -> Bool)?

        /// A closure that should be called from within an `accessibilityIncrement()` override if present.
        public let increment: (() -> Void)?

        /// A closure that should be called from within an `accessibilityDecrement()` override if present.
        public let decrement: (() -> Void)?

        public init(
            activationPoint: CGPoint? = nil,
            activate: (() -> Bool)? = nil,
            increment: (() -> Void)? = nil,
            decrement: (() -> Void)? = nil
        ) {
            self.activationPoint = activationPoint

            self.activate = activate
            self.increment = increment
            self.decrement = decrement
        }

        fileprivate init(
            activationPoint: CGPoint? = nil,
            activateAction: UIAccessibilityCustomAction? = nil,
            incrementAction: UIAccessibilityCustomAction? = nil,
            decrementAction: UIAccessibilityCustomAction? = nil
        ) {

            self.activationPoint = activationPoint

            func boolInteraction(_ action: UIAccessibilityCustomAction?) -> (() -> Bool)? {
                guard let action else { return nil }
                return { action.activate() }
            }
            func voidInteraction(_ action: UIAccessibilityCustomAction?) -> (() -> Void)? {
                guard let action else { return nil }
                return { _ = action.activate() }
            }

            activate = boolInteraction(activateAction)
            increment = voidInteraction(incrementAction)
            decrement = voidInteraction(decrementAction)
        }
    }
}

extension AccessibilityComposition {

    /// `UIAccessibilityCustomRotor` can be instantiated by providing a `SystemRotorType` rather than a name.
    /// A given accessibility element can only have a single rotor of any given `SystemRotorType` any additional rotors with that same type are ignored and inaccessible.
    /// This class takes an array of rotors and maintains them in an internal collection, cycling between their results to create a single consolidated rotor for each SystemRotorType
    /// Named rotors with SystemRotorType.none are unmodified as an element may contain any amount of theses.
    public class RotorSequencer {

        private struct RotorState {
            var rotors: [UIAccessibilityCustomRotor] = []
            var selectedRotorIndex = 0
        }

        public private(set) var rotors = [UIAccessibilityCustomRotor]()
        private var rotorsByType: [UIAccessibilityCustomRotor.SystemRotorType: RotorState] = [:]

        init(rotors: [UIAccessibilityCustomRotor]) {
            for rotor in rotors {
                if rotor.systemRotorType == .none {
                    self.rotors.append(rotor)
                } else {
                    let type = rotor.systemRotorType
                    rotorsByType[type, default: RotorState()].rotors.append(rotor)
                }
            }

            for type in rotorsByType.keys {
                let rotor = UIAccessibilityCustomRotor(systemType: type) { [weak self] predicate in
                    // returns the next result in a given search direction.
                    self?.itemSearch(type, predicate: predicate)
                }
                self.rotors.append(rotor)
            }
        }

        internal func itemSearch(
            _ type: UIAccessibilityCustomRotor.SystemRotorType,
            predicate: UIAccessibilityCustomRotorSearchPredicate
        ) -> UIAccessibilityCustomRotorItemResult? {
            if let currentRotorResult = currentRotor(type: type)?.itemSearchBlock(predicate), currentRotorResult.compare(predicate.currentItem) == false {
                return currentRotorResult
            }
            var result: UIAccessibilityCustomRotorItemResult? = nil

            while let nextRotor = nextRotor(type: type, direction: predicate.searchDirection) {
                if let nextRotorResult = nextRotor.itemSearchBlock(predicate), nextRotorResult.compare(predicate.currentItem) == false {
                    result = nextRotorResult
                    break
                }
            }
            return result
        }

        private func currentRotor(type: UIAccessibilityCustomRotor.SystemRotorType) -> UIAccessibilityCustomRotor? {
            guard let state = rotorsByType[type], state.rotors.count > 0 else { return nil }
            let index = min(state.rotors.count - 1, state.selectedRotorIndex)
            return state.rotors[index]
        }

        private func nextRotor(
            type: UIAccessibilityCustomRotor.SystemRotorType,
            direction: UIAccessibilityCustomRotor.Direction
        ) -> UIAccessibilityCustomRotor? {
            guard var state = rotorsByType[type], state.rotors.count > 0 else { return nil }
            var index = state.selectedRotorIndex

            switch direction {
            case .next:
                index += 1
            case .previous:
                index -= 1
            @unknown default:
                return nil
            }
            guard index < state.rotors.count, index >= 0 else {
                return nil
            }

            state.selectedRotorIndex = index
            rotorsByType[type] = state
            return state.rotors[index]
        }
    }
}

// MARK: AccessibilityCombinableView

extension AccessibilityComposition {

    public class CombinableView: UIView, AXCustomContentProvider, AccessibilityCombinable {

        // An accessibility representation with values that should override the combined representation
        public var overrideValues: AccessibilityComposition.CompositeRepresentation? = nil

        // An accessibility representation with values that should be merged with the combined representation
        public var mergeValues: AccessibilityComposition.CompositeRepresentation? = nil

        // If enabled, a combined view with only a single interactive child element will include the child in the accessibility representation rather than as a custom action. E.G. a button and label become a single button element.
        public var mergeInteractiveSingleChild: Bool = true

        public var traitsAdjust: (AccessibilityCombinable) -> Void = { _ in }

        public var layoutDirection: Environment.LayoutDirection = .leftToRight
        public var interfaceidiom: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom

        public var accessibilityCustomContent: [AXCustomContent]! = [] // The exclamation `!` is in the protocol definition and required.

        public var needsAccessibilityUpdate = false

        public var customFilter: Filter? = nil
        public var customSorting: Sorting? = nil

        /// When `true`, the view's `accessibilityElement` flag will mirror `hasAccessibilityRepresentation`.
        public var blockWhenNotAccessible: Bool = true

        public var rotorSequencer: AccessibilityComposition.RotorSequencer?
        public var accessibilityInteractions: AccessibilityComposition.Interactions?

        public override func accessibilityActivate() -> Bool {
            if let action = accessibilityInteractions?.activate {
                let result = action()
                if result { // update accessibility immediately to pick up any new values.
                    needsAccessibilityUpdate = true
                    updateAccessibility()
                }
                return result
            }
            return super.accessibilityActivate()
        }

        public override var accessibilityActivationPoint: CGPoint {
            get {
                accessibilityInteractions?.activationPoint ?? super.accessibilityActivationPoint
            }
            set { super.accessibilityActivationPoint = newValue }
        }

        public override func layoutSubviews() {
            super.layoutSubviews()
            updateAccessibility()
        }

        public override func accessibilityIncrement() {
            if let increment = accessibilityInteractions?.increment {
                increment()
                needsAccessibilityUpdate = true
            }
            super.accessibilityIncrement()
        }

        public override func accessibilityDecrement() {
            if let decrement = accessibilityInteractions?.decrement {
                decrement()
                needsAccessibilityUpdate = true
            }
            super.accessibilityDecrement()
        }

        private func updateAccessibility() {
            let sorting = customSorting ?? Accessibility.frameSort(
                direction: layoutDirection,
                root: self,
                userInterfaceIdiom: interfaceidiom
            )
            let accessibility = combineChildren(filter: customFilter, sorting: sorting)
                .override(with: overrideValues)
                .merge(with: mergeValues)

            applyAccessibility(
                accessibility,
                mergeInteractiveSingleChild: mergeInteractiveSingleChild
            )

            traitsAdjust(self)

            needsAccessibilityUpdate = false

            if blockWhenNotAccessible {
                isAccessibilityElement = hasAccessibilityRepresentation
            } else {
                isAccessibilityElement = true
            }
        }
    }
}

extension AccessibilityComposition.CombinableView {

    public override var isAccessibilityElement: Bool {
        get {
            if needsAccessibilityUpdate {
                updateAccessibility()
            }
            return super.isAccessibilityElement
        }
        set { super.isAccessibilityElement = newValue }
    }

    public override var accessibilityLabel: String? {
        get {
            if needsAccessibilityUpdate {
                updateAccessibility()
            }
            return super.accessibilityLabel
        }
        set { super.accessibilityLabel = newValue }
    }

    public override var accessibilityValue: String? {
        get {
            if needsAccessibilityUpdate {
                updateAccessibility()
            }
            return super.accessibilityValue
        }
        set { super.accessibilityValue = newValue }
    }

    public override var accessibilityHint: String? {
        get {
            if needsAccessibilityUpdate {
                updateAccessibility()
            }
            return super.accessibilityHint
        }
        set { super.accessibilityHint = newValue }
    }

    public override var accessibilityAttributedLabel: NSAttributedString? {
        get {
            if needsAccessibilityUpdate { updateAccessibility() }
            return super.accessibilityAttributedLabel
        }
        set { super.accessibilityAttributedLabel = newValue }
    }

    public override var accessibilityAttributedValue: NSAttributedString? {
        get {
            if needsAccessibilityUpdate { updateAccessibility() }
            return super.accessibilityAttributedValue
        }
        set { super.accessibilityAttributedValue = newValue }
    }

    public override var accessibilityAttributedHint: NSAttributedString? {
        get {
            if needsAccessibilityUpdate { updateAccessibility() }
            return super.accessibilityAttributedHint
        }
        set { super.accessibilityAttributedHint = newValue }
    }

    public override var accessibilityIdentifier: String? {
        get {
            if needsAccessibilityUpdate {
                updateAccessibility()
            }
            return super.accessibilityIdentifier
        }
        set { super.accessibilityIdentifier = newValue }
    }

    public override var accessibilityElements: [Any]? {
        get {
            if needsAccessibilityUpdate {
                updateAccessibility()
            }
            return super.accessibilityElements
        } set {
            super.accessibilityElements = newValue
        }
    }
}

@available(iOS 17.0, *)
extension AccessibilityComposition.CombinableView {

    public override var isAccessibilityElementBlock: AXBoolReturnBlock? {
        get {
            if needsAccessibilityUpdate {
                updateAccessibility()
            }

            return super.isAccessibilityElementBlock
        }
        set { super.isAccessibilityElementBlock = newValue }
    }

    public override var accessibilityElementsBlock: AXArrayReturnBlock? {
        get {
            if needsAccessibilityUpdate {
                updateAccessibility()
            }
            return super.accessibilityElementsBlock
        }
        set { super.accessibilityElementsBlock = newValue }
    }

    public override var accessibilityLabelBlock: AXStringReturnBlock? {
        get {
            if needsAccessibilityUpdate {
                updateAccessibility()
            }
            return super.accessibilityLabelBlock
        }
        set { super.accessibilityLabelBlock = newValue }
    }

    public override var accessibilityValueBlock: AXStringReturnBlock? {
        get {
            if needsAccessibilityUpdate {
                updateAccessibility()
            }
            return super.accessibilityValueBlock
        }
        set { super.accessibilityValueBlock = newValue }
    }

    public override var accessibilityHintBlock: AXStringReturnBlock? {
        get {
            if needsAccessibilityUpdate {
                updateAccessibility()
            }
            return super.accessibilityHintBlock
        }
        set { super.accessibilityHintBlock = newValue }
    }

    public override var accessibilityIdentifierBlock: AXStringReturnBlock? {
        get {
            if needsAccessibilityUpdate {
                updateAccessibility()
            }
            return super.accessibilityIdentifierBlock
        }
        set { super.accessibilityIdentifierBlock = newValue }
    }

    public override var accessibilityTraitsBlock: AXTraitsReturnBlock? {
        get {
            if needsAccessibilityUpdate {
                updateAccessibility()
            }
            return super.accessibilityTraitsBlock
        }
        set { super.accessibilityTraitsBlock = newValue }
    }
}


// MARK: Protocol

public protocol AccessibilityCombinable: NSObject, UIAccessibilityIdentification, AXCustomContentProvider {
    // A boolean that indicates that the accessibility representation is stale.
    // this should be set to `true` when the content or state changes.
    // This should be checked in accessibility property getters and should run an update pass before returning any value.
    var needsAccessibilityUpdate: Bool { get set }

    // An object type that coordinates rotor combinatorics.
    var rotorSequencer: AccessibilityComposition.RotorSequencer? { get set }

    // Provides closures that should be called from their associated accessibility function overrides.
    var accessibilityInteractions: AccessibilityComposition.Interactions? { get set }
}

extension AccessibilityCombinable {

    /// Applies the combined accessibility representation to this element.
    /// - Parameter mergeInteractiveSingleChild: Use the first interactive child's traits and
    ///   activation when it is the only interactive child or all children are interactive.
    ///   Set this to `false` when the receiving element supplies its own activation.
    ///
    public func applyAccessibility(
        _ accessibility: AccessibilityComposition.CompositeRepresentation?,
        mergeInteractiveSingleChild: Bool = true
    ) {
        rotorSequencer = nil
        accessibilityInteractions = nil
        needsAccessibilityUpdate = accessibility == nil

        accessibilityAttributedLabel = accessibility?.attributedLabel
        accessibilityAttributedValue = accessibility?.attributedValue
        accessibilityAttributedHint = accessibility?.attributedHint
        accessibilityTraits = accessibility?.traits ?? .none
        accessibilityIdentifier = accessibility?.identifier

        rotorSequencer = AccessibilityComposition.RotorSequencer(rotors: accessibility?.rotors ?? [])
        accessibilityCustomRotors = rotorSequencer?.rotors

        accessibilityCustomContent = accessibility?.customContent ?? []


        let shouldMergeFirstChild: Bool = {
            guard mergeInteractiveSingleChild, let children = accessibility?.interactiveChildren else { return false }
            return children.count == 1 || children.count == accessibility?.elementsCount
        }()

        if shouldMergeFirstChild,
           let child = accessibility?.interactiveChildren?.first
        {
            accessibilityAttributedLabel = [accessibilityAttributedLabel, child.attributedLabel].removingDuplicates.joinedAccessibilityText()
            accessibilityAttributedValue = [accessibilityAttributedValue, child.attributedValue].removingDuplicates.joinedAccessibilityText()
            accessibilityAttributedHint = [accessibilityAttributedHint, child.attributedHint].removingDuplicates.joinedAccessibilityText()
            accessibilityIdentifier = [accessibilityIdentifier, child.identifier].removingDuplicates.compactMap { $0 }.joined(separator: "-")
            accessibilityTraits = accessibilityTraits.union(child.traits)
            if let rotors = child.rotors, !rotors.isEmpty {
                accessibilityCustomRotors = (accessibilityCustomRotors ?? []) + rotors
            }
            accessibilityInteractions = .init(
                activationPoint: child.activationPoint,
                activateAction: child.actions.activationAction,
                incrementAction: child.actions.increment,
                decrementAction: child.actions.decrement
            )

            var actions = accessibility?.allActions ?? []

            if let childActions = child.actions.customActions {
                actions.append(contentsOf: childActions)
            }

            let otherChildActions = (accessibility?.interactiveChildren ?? [])
                .dropFirst()
                .compactMap { $0.allActions }
                .flatMap { $0 }
            actions.append(contentsOf: otherChildActions)

            accessibilityCustomActions = actions.isEmpty ? nil : actions

        } else {
            let existingActions = accessibility?.allActions ?? []
            let allActions = ((accessibility?.interactiveChildren ?? []).compactMap { $0.allActions }.joined()) + existingActions
            accessibilityCustomActions = allActions.isEmpty ? nil : allActions

            // Resolve each child's value using its traits before adding it to the combined value.
            if let values = accessibility?.interactiveChildren?.compactMap({ $0.traits.interpret(value: $0.attributedValue) }) {
                accessibilityAttributedValue = ([accessibilityAttributedValue] + values).joinedAccessibilityText()
            }
        }
        accessibilityCustomActions = accessibilityCustomActions?.filter { !$0.name.isEmpty }

    }
}

// MARK: Extensions - Element Recursion and inclusion

extension AccessibilityCombinable where Self: UIView {
    public func combineChildren(
        filter: AccessibilityComposition.Filter? = nil,
        sorting: AccessibilityComposition.Sorting? = nil,
        ignoreInteractive: Bool = true
    ) -> AccessibilityComposition.CompositeRepresentation {

        let elements = recursiveAccessibleElements(filter: filter, sorting: sorting)
        return AccessibilityComposition.CompositeRepresentation(elements, ignoreInteractive: ignoreInteractive) { [weak self] in
            self?.needsAccessibilityUpdate = true
        }
    }
}

extension UIView {
    internal func recursiveAccessibleElements(
        filter: AccessibilityComposition.Filter? = nil,
        sorting: AccessibilityComposition.Sorting? = nil
    ) -> [NSObject] {
        let elements = subviews.flatMap { subview -> [NSObject] in
            if subview.accessibilityElementsHidden || subview.isHidden {
                return []
            } else if let accessibilityElements = subview.accessibilityElements {
                return accessibilityElements.compactMap { $0 as? NSObject }
            } else if subview.isAccessibilityElement {
                return [subview]
            } else {
                return subview.recursiveAccessibleElements(filter: filter, sorting: sorting)
            }
        }
        return elements
            .filter { filter?($0) ?? true }
            .sorted(by: sorting ?? { _, _ in true })
    }
}

extension NSObject {
    internal var isLikelyInteractive: Bool {
        var likely = false
        if hasInteractiveTraits {
            likely = true
        }

        if let view = self as? UIView {
            if view is UIControl {
                likely = true
            }
            if !view.isUserInteractionEnabled {
                likely = false
            }
        }
        return likely
    }

    internal var isAccessibilityEnabled: Bool {
        if let control = self as? UIControl {
            return control.isEnabled
        }
        return true
    }

    private var hasInteractiveTraits: Bool {
        !accessibilityTraits.intersection(
            .init(with: [
                .button,
                .link,
                .playsSound,
                .toggleButton,
            ])
        ).isEmpty
    }

    /// Returns `true` if there is a non-empty hint, label, or value.
    internal var hasAccessibilityRepresentation: Bool {
        !(accessibilityHint ?? "").isEmpty ||
            !(accessibilityLabel ?? "").isEmpty ||
            !(accessibilityValue ?? "").isEmpty
    }
}

// MARK: Extensions - Element Activation

extension NSObject {
    @objc fileprivate func accessibilityAction(didFire: @escaping (String, Bool) -> Void) -> UIAccessibilityCustomAction {
        let name: String = {
            if let value = accessibilityTraits.interpret(value: accessibilityAttributedValue ?? accessibilityValue.map(NSAttributedString.init(string:))), value.length > 0,
               let label = accessibilityLabel, !label.isEmpty
            {
                return "\(label): \(value.string)"
            }
            // Unnamed actions can supply activation but are omitted from the Actions rotor.
            return accessibilityLabel ?? ""
        }()

        // Voiceover prefers the action handler if it's available, so we'll create the action using that init method.
        let action = UIAccessibilityCustomAction(name: name, actionHandler: { [weak self] _ in
            let result = self?.accessibilityActivate() ?? false
            didFire(name, result)
            return result
        })

        // It is important that we also set the target: selector: syntax as we'll be grabbing the accessibilityActivationPoint from the target object later.
        action.target = self
        action.selector = #selector(accessibilityActionActivate)
        return action
    }

    @objc private func accessibilityActionActivate(_ action: UIAccessibilityCustomAction) -> NSNumber {
        // Wrap in an NSNumber so it can be returned using perform(:with:) rather than NSInvocation APIs (which aren't available to swift)
        NSNumber(booleanLiteral: accessibilityActivate())
    }

    fileprivate var accessibilityIncrementDecrementActions: (
        increment: UIAccessibilityCustomAction,
        decrement: UIAccessibilityCustomAction
    )? {
        guard accessibilityTraits.contains(.adjustable) else { return nil }
        let name = accessibilityLabel ?? accessibilityValue ?? ""

        return (
            increment: UIAccessibilityCustomAction(name: "\(LocalizedStrings.Accessibility.increment) \(name)".trimmingCharacters(in: .whitespaces)) { [weak self] _ in
                self?.accessibilityIncrement()
                return true
            },
            decrement: UIAccessibilityCustomAction(name: "\(LocalizedStrings.Accessibility.decrement) \(name)".trimmingCharacters(in: .whitespaces)) { [weak self] _ in
                self?.accessibilityDecrement()
                return true
            }
        )
    }

    fileprivate var extractedAccessibilityIdentifier: String? {
        // The `accessibilityIdentifier` property is separated from the rest of the accessibility properties in that its a separate protocol defined in `UIKit.UIAccessibilityIdentification`
        if let viaProtocol = self as? UIAccessibilityIdentification {
            return viaProtocol.accessibilityIdentifier
        }

        // Swift sometimes fails to detect that subclasses of Objective C types conform to the above.
        // This is most likely due to a Swift bug related to converting Objc classes into `Any` types which are used by Swift for accessibility APIs (rather than `NSObject` in UIKit).
        // See https://github.com/swiftlang/swift/issues/46456 for more information about this issue.

        // This case in particular is a little different because `self` is already an `NSObject`, so the proposed solution of casting `self as AnyObject` doesn't work.
        // The below types have conformance defined alongside the protocol definition itself. If we can cast ourselves into any of these types we're going to be able to use the identifier.

        if let view = self as? UIView {
            return view.accessibilityIdentifier
        }
        if let barItem = self as? UIBarItem {
            return barItem.accessibilityIdentifier
        }
        if let alertAction = self as? UIAlertAction {
            return alertAction.accessibilityIdentifier
        }
        if let menuElement = self as? UIMenuElement {
            return menuElement.accessibilityIdentifier
        }
        if let image = self as? UIImage {
            return image.accessibilityIdentifier
        }
        return nil
    }
}

extension UIAccessibilityCustomAction {
    // iOS 13 brought us UIAccessibilityCustomActionHandler which, if defined, takes precedence over the target/selector pair.
    // This helper fires the action, taking this distinction into account.

    // Like `accessibilityActivate()` the return Bool indicates the success or failure of the operation.
    internal func activate() -> Bool {
        if let handler = actionHandler {
            return handler(self)
        }
        // `perform(:with:)` can only return a reference type so for our purposes it's wrapped in an NSNumber.
        return (target?.perform(selector, with: self).takeUnretainedValue() as? NSNumber)?.boolValue ?? false
    }
}

// MARK: Extensions - Element Sorting and Comparison

extension UIAccessibilityTraits {

    // Localize toggle values before they become part of a longer announcement or action name.
    func interpret(value: NSAttributedString?) -> NSAttributedString? {
        if let value, contains(.init(with: [.toggleButton])), let toggleValue = Accessibility.ToggleValue(string: value.string) {
            let interpreted = NSMutableAttributedString(attributedString: value)
            interpreted.replaceCharacters(
                in: NSRange(location: 0, length: interpreted.length),
                with: toggleValue.description
            )
            return interpreted
        }
        return value
    }
}

extension UIAccessibilityCustomRotorItemResult {
    fileprivate func compare(_ other: UIAccessibilityCustomRotorItemResult) -> Bool {
        // 'any NSObjectProtocol' cannot be used as a type conforming to protocol 'Equatable' because 'Equatable' has static requirements
        let target = targetElement as? NSObject
        let otherTarget = other.targetElement as? NSObject
        return target == otherTarget && targetRange == other.targetRange
    }
}

extension Accessibility {

    internal enum ToggleValue: Int, CustomStringConvertible {

        /// When combined with the .toggleButton trait, accessibilityValues of 0, 1, and 2 are read in localized
        /// values "off",  "on", and "mixed".
        case off = 0
        case on = 1
        case mixed = 2

        init?(string: String) {
            guard let raw = Int(string) else { return nil }
            self.init(rawValue: raw)
        }

        var description: String {
            switch self {
            case .off: LocalizedStrings.Accessibility.ToggleButton.offValue
            case .on: LocalizedStrings.Accessibility.ToggleButton.onValue
            case .mixed: LocalizedStrings.Accessibility.ToggleButton.mixedValue
            }
        }

        var accessibilityValue: String {
            "\(rawValue)"
        }
    }
}

