import BlueprintUI
import UIKit


/// Allows elements to defer responsibility for their accessibility content to their contained children.
/// This can be used by container elements to pass along context to be exposed by participating child elements.
/// The most exemplary use case is a FieldContainer deferring error and helper accessibility to a contained TextView.
public struct AccessibilityDeferral {

    /// AccessibilityDeferral searches the contained view hierarchy for participating views and then passes the accessibility content between them.
    public protocol DeferralView: UIView {}

    /// An accessibility element that accepts the deferred accessibility content and exposes it via AccessibilityCustomContent.
    /// In our example case this is the text view which should expose the error content.
    /// An AccessibilityDeferral.Container will apply accessibility content to up to one (1) deferral views in its child view hierarchy.
    public protocol Receiver: DeferralView, AXCustomContentProvider {

        /// An object type that coordinates rotor combinatorics.
        var rotorSequencer: AccessibilityComposition.RotorSequencer? { get set }

        /// Custom content that may be supplied in addition to the deferred content
        var customContent: [Accessibility.CustomContent]? { get set }

        /// Content from an outside source that will be exposed via AccessibilityCustomContent
        var deferredAccessibilityContent: [AccessibilityDeferral.Content]? { get set }

        /// Called by the parent container. Default implementation provided.
        /// - parameter content: the accessibility content to apply to the receiver.
        func applyDeferredAccessibility(
            content: [AccessibilityDeferral.Content]?
        )
    }

    /// An accessibility container wrapping an element that natively provides the deferred accessibility content. This element's accessibility is conditionally exposed based on the presence of a receiver.
    /// In the example case, this is the error label view that appears under the text field.
    /// An AccessibilityDeferral.ParentContainer may contain multiple source views in its child view hierarchy.
    public protocol Source: DeferralView {
        /// An identifier used to match the source and content.
        var contentIdentifier: AnyHashable? { get }

        /// The inherited accessibility of the contained  element..
        var accessibility: AccessibilityComposition.CompositeRepresentation? { get }
    }

    public struct Content: Equatable {
        public enum Kind: Equatable {
            /// Uses accessibility values from the contained element and exposes them as custom via the accessiblity rotor.
            case inherited(Accessibility.CustomContent.Importance = .default)
            /// Announces an error message with high importance using accessibility values from the contained element.
            case error
            /// Exposes the custom content provided.
            case custom(Accessibility.CustomContent)
        }

        public var kind: Kind

        /// Used to identify a specific `Source` element to inherit accessibility from.
        public var sourceIdentifier: AnyHashable

        /// : A stable identifier used to identify a given update pass through he view hierarchy. Content with matching updateIdentifiers should be combined.
        internal var updateIdentifier: UUID?
        internal var inheritedAccessibility: AccessibilityComposition.CompositeRepresentation?

        public init(kind: Kind = .inherited(), identifier: AnyHashable = NSUUID()) {
            self.kind = kind
            sourceIdentifier = identifier
        }

        public var customContent: AXCustomContent? {
            switch kind {
            case .inherited(let importance):
                return inheritedAccessibility?.makeContent(importance: importance)?.axCustomContent
            case .error:
                guard let inheritedAccessibility else { return nil }
                var content = inheritedAccessibility.makeContent(importance: .high)
                let value = [content?.label, content?.value].joinedAccessibilityString()
                content?.value = value
                content?.label = LocalizedStrings.Accessibility.errorTitle
                return content?.axCustomContent
            case .custom(let customContent):
                return customContent.axCustomContent
            }
        }
    }
}

extension Element {
    /// Creates the `ParentContainer` to manage the accessibility deferral.
    /// - parameter content: the accessibility content to apply to the receiver.
    public func deferAccessibilityToChildren(content: [AccessibilityDeferral.Content]) -> AccessibilityDeferral.ParentContainer {
        AccessibilityDeferral.ParentContainer(
            content: content,
            wrapping: { self }
        )
    }

    /// Creates a `SourceContainer` element to wrap the conditionally exposed element.
    public func deferredAccessibilitySource(identifier: AnyHashable) -> AccessibilityDeferral.SourceContainer {
        AccessibilityDeferral.SourceContainer(wrapping: { self }, identifier: identifier)
    }
}

extension AccessibilityDeferral {

    /// The parent container element which contains both `Source` and `Receiver` sibling views and passes the content between them.
    /// This container must contain only a single `Receiver` view but may have multiple `Source` views.
    public struct ParentContainer: Element {

        public var wrappedElement: Element
        public var deferredContent: [Content]

        public var content: ElementContent {
            ElementContent(child: wrappedElement)
        }

        public func backingViewDescription(with context: BlueprintUI.ViewDescriptionContext) -> BlueprintUI.ViewDescription? {
            DeferralContainerView.describe { config in
                config[\.contents] = deferredContent
            }
        }

        public init(
            content: [Content],
            wrapping element: @escaping () -> Element
        ) {
            deferredContent = content
            wrappedElement = element()
        }
    }

    private final class DeferralContainerView: UIView {

        var useContainerFrame: Bool = true
        var contents: [Content]? {
            didSet {
                if oldValue != contents {
                    // We can't call updateAccessibility() directly because we need the rest of the blueprint pass to complete or the source views won't have matching identifiers.
                    setNeedsLayout()
                }
            }
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            updateAccessibility()
        }


        private var updateID: UUID? {
            didSet {
                if oldValue != updateID, updateID != nil {
                    // recursiveSubviews(matching:) does not recurse into a successful match, returning only the "first layer" of hits.
                    // This works fine when traversing a structure like the accessibility hierarchy where each node is either a container or an element and we're attempting to match the elements. But in this case we're looking for containers within containers so we have to apply it layer by layer so to speak.
                    propagateUpdateID(updateID)
                }
            }
        }

        private func propagateUpdateID(_ id: UUID?) {
            // Set the update ID for child containers.
            // Note that we don't set the updateID property on self. This ensures that the outermost container generates a new UUID for each update and that the accessibility of child containers will be combined rather than overwriting one another.
            recursiveSubviews(matching: { $0 != self && $0 is DeferralContainerView })
                .forEach { ($0 as? DeferralContainerView)?.updateID = id }
        }

        private func updateAccessibility() {
            let views = recursiveSubviews(matching: { $0 is DeferralView })
            let receivers = views.filter { $0 is Receiver } as! [Receiver]
            let sources = views.filter { $0 is Source } as! [Source]

            let updateID = updateID ?? UUID()
            propagateUpdateID(updateID)

            // Reset source views.
            sources.forEach { $0.accessibilityElementsHidden = false }


            guard receivers.count <= 1 else {
                // We cannot reasonably determine which receiver to apply the content to.
                receivers.forEach { $0.applyDeferredAccessibility(
                    content: nil
                ) }
                return
            }


            if let receiver = receivers.first {

                // Inherit accessibility content and disable source element.
                let deferredContent = contents?.map { content in
                    var updated = content
                    let matches = sources.filter { $0.contentIdentifier == content.sourceIdentifier }
                    guard matches.count <= 1 else { fatalError("Found multiple deferral sources with the same identifier. \(matches)") }
                    let match = matches.first
                    match?.accessibilityElementsHidden = true
                    updated.inheritedAccessibility = match?.accessibility
                    updated.updateIdentifier = updateID
                    return updated
                }

                // Apply content to receiver.
                receiver.applyDeferredAccessibility(
                    content: deferredContent
                )
            }
        }
    }
}


extension AccessibilityDeferral {

    public struct SourceContainer: Element {
        public var wrappedElement: Element
        public var identifier: AnyHashable

        init(wrapping: @escaping () -> Element, identifier: AnyHashable) {
            wrappedElement = wrapping()
            self.identifier = identifier
        }

        public var content: ElementContent {
            ElementContent(measuring: wrappedElement)
        }

        public func backingViewDescription(with context: BlueprintUI.ViewDescriptionContext) -> BlueprintUI.ViewDescription? {
            SourceContainerView.describe { config in
                config[\.contentIdentifier] = identifier
                config[\.element] = wrappedElement
            }
        }
    }

    // This view contains the accessibility source element. It will be excluded from accessibility if the receiver exists.
    private final class SourceContainerView: UIView, Source {

        var contentIdentifier: AnyHashable?
        private var needsAccessibilityUpdate = true
        private var _accessibility: AccessibilityComposition.CompositeRepresentation?
        var accessibility: AccessibilityComposition.CompositeRepresentation? {
            if needsAccessibilityUpdate {
                updateAccessibility()
            }
            return _accessibility
        }

        var element: Element? {
            didSet {
                blueprintView.element = element
                needsAccessibilityUpdate = true
            }
        }

        private var blueprintView = BlueprintView()

        override init(frame: CGRect) {
            super.init(frame: frame)
            isAccessibilityElement = false

            blueprintView.backgroundColor = .clear
            addSubview(blueprintView)
        }

        override func addSubview(_ view: UIView) {
            super.addSubview(view)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            blueprintView.frame = bounds
            needsAccessibilityUpdate = true
        }

        private func updateAccessibility() {
            needsAccessibilityUpdate = false
            blueprintView.layoutIfNeeded()
            let elements = blueprintView.recursiveAccessibleElements()
            _accessibility = AccessibilityComposition.CompositeRepresentation(elements, ignoreInteractive: false) { [weak self] in
                self?.needsAccessibilityUpdate = true
            }
        }
    }
}

extension UIView {
    internal func recursiveSubviews(matching test: (UIView) -> Bool) -> [UIView] {
        if test(self) {
            return [self]
        }
        var matches = [UIView]()
        for subview in subviews {
            matches += subview.recursiveSubviews(matching: test)
        }
        return matches
    }
}

extension Accessibility.CustomContent.Importance {
    fileprivate var axImportance: AXCustomContent.Importance {
        switch self {
        case .default: .default
        case .high: .high
        }
    }
}

extension AccessibilityComposition.CompositeRepresentation {
    fileprivate func makeContent(importance: Accessibility.CustomContent.Importance) -> Accessibility.CustomContent? {
        if let allActions, allActions.contains(where: { $0.name == label }) {
            // we don't want to duplicate custom actions and content so if we have an action with the same label, prefer the action.
            return nil
        }

        if let label {
            return .init(label: label, value: value, importance: importance)
        } else if let value {
            return .init(label: value, importance: importance)
        }
        return nil

    }
}

/// Default Implementation
extension AccessibilityDeferral.Receiver {

    public func applyDeferredAccessibility(
        content: [AccessibilityDeferral.Content]?
    ) {
        guard let content, !content.isEmpty else { replaceContent([]); return }
        guard let updateID = content.first?.updateIdentifier, content.allSatisfy({ $0.updateIdentifier == updateID }) else {
            fatalError("Cannot merge deferral content as update identifiers do not match.")
        }
        let lastUpdateID = deferredAccessibilityContent?.first?.updateIdentifier

        if lastUpdateID == updateID {
            mergeContent(content)
        } else {
            replaceContent(content)
        }

        func replaceContent(_ content: [AccessibilityDeferral.Content]?) {
            deferredAccessibilityContent = content

            accessibilityCustomActions = content?.compactMap { $0.inheritedAccessibility?.allActions }.flatMap { $0 }.removingDuplicateActions()

            if let rotors = content?.compactMap({ $0.inheritedAccessibility?.rotors }).flatMap({ $0 }), !rotors.isEmpty {
                rotorSequencer = .init(rotors: rotors)
            } else {
                rotorSequencer = nil
            }
        }

        func mergeContent(_ content: [AccessibilityDeferral.Content]?) {
            deferredAccessibilityContent = (deferredAccessibilityContent + content)?.removingDuplicates

            let contentActions = content?.compactMap { $0.inheritedAccessibility?.allActions }.flatMap { $0 }
            accessibilityCustomActions = (accessibilityCustomActions + contentActions)?.removingDuplicateActions()

            if let rotors = content?.compactMap({ $0.inheritedAccessibility?.rotors }).flatMap({ $0 }), !rotors.isEmpty {
                let mergedRotors = (rotorSequencer?.rotors ?? []) + rotors
                rotorSequencer = .init(rotors: mergedRotors)
                accessibilityCustomRotors = rotorSequencer?.rotors
            }
        }
    }
}
