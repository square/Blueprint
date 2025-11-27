import BlueprintUI
import UIKit

public struct AccessibilitySetter: Element {

    // The wrapped element
    private var wrappedElement: Element

    private var label: String?
    private var value: String?
    private var hint: String?
    private var identifier: String?
    private var traits: Set<Accessibility.Trait>?

    private var mergeInteractiveSingleChild: Bool

    public init(
        wrapping element: @escaping () -> Element,
        label: String? = nil,
        value: String? = nil,
        hint: String? = nil,
        identifier: String? = nil,
        accessibilityTraits: Set<Accessibility.Trait>? = nil,
        mergeInteractiveSingleChild: Bool = true
    ) {
        wrappedElement = element()
        self.label = label
        self.value = value
        self.hint = hint
        self.identifier = identifier
        traits = accessibilityTraits
        self.mergeInteractiveSingleChild = mergeInteractiveSingleChild
    }

    public var content: ElementContent {
        ElementContent(child: wrappedElement)
    }

    private func combined(invalidator: @escaping () -> Void) -> AccessibilityComposition.CompositeRepresentation {
        var new = AccessibilityComposition.CompositeRepresentation([], invalidator: invalidator)
        new.label = label
        new.value = value
        new.hint = hint
        new.identifier = identifier
        new.traits = UIAccessibilityTraits(with: traits ?? [])
        return new
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        AccessibilityComposition.CombinableView.describe { config in
            config.apply { view in
                view.isAccessibilityElement = true
                view.needsAccessibilityUpdate = true
                view.layoutDirection = context.environment.layoutDirection
                view.overrideValues = combined { [weak view] in
                    view?.needsAccessibilityUpdate = true
                }
                view.mergeInteractiveSingleChild = mergeInteractiveSingleChild

                if let adjustable = traits?.first(where: { $0.isAdjustable }),
                   case .adjustable(let incrementAction, let decrementAction) = adjustable
                {
                    view.accessibilityInteractions = AccessibilityComposition.Interactions(
                        activationPoint: view.accessibilityInteractions?.activationPoint,
                        activate: view.accessibilityInteractions?.activate,
                        increment: incrementAction,
                        decrement: decrementAction
                    )
                }
            }
        }
    }
}

public struct AccessibilityTraitsAdjust: Element {

    // The wrapped element
    public var wrappedElement: Element
    private var add: Set<Accessibility.Trait> = []
    private var remove: Set<Accessibility.Trait> = []

    private var adjustment: ((UIAccessibilityTraits) -> UIAccessibilityTraits)? {
        { $0.union(UIAccessibilityTraits(with: add)).subtracting(UIAccessibilityTraits(with: remove)) }
    }

    public init(
        wrapping element: @escaping () -> Element,
        add: Set<Accessibility.Trait> = [],
        remove: Set<Accessibility.Trait> = []
    ) {
        wrappedElement = element()
        self.add = add
        self.remove = remove
    }

    public var content: ElementContent {
        ElementContent(child: wrappedElement)
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        AccessibilityComposition.CombinableView.describe { config in
            config.apply { view in
                view.isAccessibilityElement = true
                view.needsAccessibilityUpdate = true
                view.layoutDirection = context.environment.layoutDirection
                view.traitsAdjust = { [weak view] combinable in
                    guard let view else { return }

                    // First apply additions and subtractions
                    combinable.accessibilityTraits = combinable.accessibilityTraits.union(UIAccessibilityTraits(with: add)).subtracting(UIAccessibilityTraits(with: remove))

                    // update the increment and decrement overrides
                    if let adjustableAdd = add.first(where: { $0.isAdjustable }),
                       case .adjustable(let incrementAction, let decrementAction) = adjustableAdd
                    {
                        view.accessibilityInteractions = AccessibilityComposition.Interactions(
                            activationPoint: view.accessibilityInteractions?.activationPoint,
                            activate: view.accessibilityInteractions?.activate,
                            increment: incrementAction,
                            decrement: decrementAction
                        )
                    }
                    if remove.contains(where: { $0.isAdjustable }) {
                        if let interactions = view.accessibilityInteractions {
                            view.accessibilityInteractions = .init(
                                activationPoint: interactions.activationPoint,
                                activate: interactions.activate
                            )
                        }
                    }
                }
            }
        }
    }
}

extension Element {

    /// An similar declaration that hides the mergeInteractiveSingleChild parameter exists in BlueprintUiCommonControls.
    public func accessibility(
        label: String? = nil,
        value: String? = nil,
        hint: String? = nil,
        traits: Set<Accessibility.Trait>? = nil,
        identifier: String? = nil,
        mergeInteractiveSingleChild: Bool
    ) -> Element {
        AccessibilitySetter(
            wrapping: { self },
            label: label,
            value: value,
            hint: hint,
            identifier: identifier,
            accessibilityTraits: traits,
            mergeInteractiveSingleChild: mergeInteractiveSingleChild
        )
    }
}
