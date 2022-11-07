//
//  ElementState.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 6/24/21.
//

import Foundation
import UIKit


/// The root node in an `ElementState` tree, which is used by `BlueprintView`
/// to maintain state across multiple layout passes.
final class ElementStateTree {

    /// The root element in the tree. Nil if there is no element.
    private(set) var root: ElementState?

    /// A signpost token used for logging signposts to `os_log`.
    private let signpostRef: SignpostToken = .init()

    /// An optional delegate to be informed about the layout process.
    weak var delegate: ElementStateTreeDelegate? = nil {
        didSet {
            guard oldValue !== delegate else { return }

            root?.recursiveForEach {
                $0.delegate = delegate
            }
        }
    }

    /// A human readable name that represents the tree. Useful for debugging.
    var name: String {
        didSet {
            guard oldValue == name else { return }

            root?.recursiveForEach {
                $0.name = name
            }
        }
    }

    init(name: String) {
        self.name = name
    }

    /// Updates, replaces, or removes the root node depending on the type of the new element.
    func update(with element: Element?, in environment: Environment) {

        func makeRoot(with element: Element) -> ElementState {
            let new = ElementState(
                parent: nil,
                delegate: delegate,
                identifier: .identifier(for: element, key: nil, count: 1),
                element: element,
                depth: 0,
                signpostRef: signpostRef,
                name: name
            )

            root = new

            return new
        }

        if root == nil, let element = element {
            /// Transition from no root element, to root element.
            let new = makeRoot(with: element)

            delegate.perform {
                $0.tree(self, didSetupRootState: new)
            }
        } else if root != nil, element == nil {
            /// Transition from a root element, to no root element.
            let old = root
            root = nil

            delegate.perform {
                $0.tree(self, didTeardownRootState: old!)
            }
        } else if let root = self.root, let element = element {
            if type(of: root.element.value) == type(of: element) {
                /// The type of the new element is the same, update inline.
                root.update(with: element, in: environment, identifier: root.identifier)

                delegate.perform {
                    $0.tree(self, didUpdateRootState: root)
                }
            } else {
                /// The type of the root element changed, replace it.
                let new = makeRoot(with: element)

                delegate.perform {
                    $0.tree(self, didReplaceRootState: root, with: new)
                }
            }
        }
    }
}


/// A reference type passed through to `LayoutResultNode` and `NativeViewNode`,
/// so that even when returning cached layouts, we can get to the latest version of the element
/// that their originating `ElementState` represents.
final class ElementSnapshot {

    fileprivate(set) var value: Element

    init(_ value: Element) {
        self.value = value
    }
}


/// Represents the live, on screen state for a given element in the element tree.
///
/// `ElementState` is updated with the newest state of its backing `Element`
/// during the layout pass, and retains cached information such as measurements
/// and layouts either to the end of the layout pass, or until the equivalency of the `Element`
/// changes, for comparable elements.
final class ElementState {

    /// The parent element that owns this element.
    private(set) weak var parent: ElementState?

    fileprivate(set) weak var delegate: ElementStateTreeDelegate? = nil

    /// The identifier of the element. Eg, `Inset.1` or `Inset.1.Key`.
    let identifier: ElementIdentifier

    /// The depth of the element within the element tree.
    let depth: Int

    /// The signpost ref used when logging to `os_log`.
    let signpostRef: AnyObject

    /// The name of the owning tree. Useful for debugging.
    var name: String

    /// The element represented by this object.
    /// This value is a reference type – the inner element value
    /// will change after updates.
    let element: ElementSnapshot

    /// How and if the element should be compared during updates.
    let comparability: Comparability

    /// If the node has been visited this layout cycle.
    /// If `false`, the node will be torn down and garbage collected
    /// at the end of the layout cycle.
    private(set) var wasVisited: Bool

    /// If the update during this layout cycle was equivalent.
    /// Useful for debugging.
    private(set) var wasUpdateEquivalent: Bool

    /// The cached measurements for the current node.
    /// Measurements are cached by a `SizeConstraint` key, meaning that
    /// there can be multiple cached measurements for the same element.
    private var measurements: [SizeConstraint: CachedMeasurement] = [:]

    /// The cached layouts for the current node.
    /// Layouts are cached by a `CGSize` key, meaning that
    /// we can preserve multiple layouts if the containing element or containing
    /// view's size changes, eg when rotating from portait to landscape.
    private var layouts: [CGSize: CachedLayout] = [:]

    /// The children of the `ElementState`, cached by element identifier.
    private var children: [ElementIdentifier: ElementState] = [:]

    /// The children of the element state in the order they appear in the Layout.
    /// This value is built dynamically as the element tree is enumerated.
    private(set) var orderedChildren: [ElementState] = []

    /// Indicates the comparability behavior of the element.
    enum Comparability: Equatable {
        /// The element is not comparable, and it is not the child of a comparable element.
        case notComparable

        /// The element is comparable itself; it conforms to `ComparableElement`.
        case comparableElement

        /// The element is the child of a `ComparableElement`, meaning its comparability
        /// is determined by the comparability of that parent element.
        case childOfComparableElement

        /// If the element is either directly comparable, or the child of a `ComparableElement`.
        var isComparable: Bool {
            switch self {
            case .notComparable: return false
            case .comparableElement: return true
            case .childOfComparableElement: return true
            }
        }
    }

    /// Creates a new `ElementState` instance.
    init(
        parent: ElementState?,
        delegate: ElementStateTreeDelegate?,
        identifier: ElementIdentifier,
        element: Element,
        depth: Int,
        signpostRef: AnyObject,
        name: String
    ) {
        self.parent = parent
        self.delegate = delegate
        self.identifier = identifier
        self.element = ElementSnapshot(element)

        if element is AnyComparableElement {
            comparability = .comparableElement
        } else {
            if let parent = parent {
                switch parent.comparability {
                case .notComparable:
                    comparability = .notComparable
                case .comparableElement, .childOfComparableElement:
                    comparability = .childOfComparableElement
                }
            } else {
                comparability = .notComparable
            }
        }

        self.depth = depth
        self.signpostRef = signpostRef
        self.name = name

        wasVisited = true
        wasUpdateEquivalent = false
    }

    /// Assigned once per layout cycle, this value represents the
    /// `Element.content` value from the represented element.
    /// This value is cached to improve performance (fewer allocations and
    /// less repeated content building), as well as improves debuggability.
    private var cachedContent: ElementContent?

    /// Allows the layout system in `ElementContent` to access the `ElementContent`
    /// of the element, returning a cached version after the first access during a layout cycle.
    var elementContent: ElementContent {
        if let cachedContent = cachedContent {
            return cachedContent
        } else {
            let content = element.value.content
            cachedContent = content

            delegate.perform {
                $0.treeDidFetchElementContent(for: self)
            }

            return content
        }
    }

    /// Updates the element state with the new element and new environment,
    /// throwing away cached values if needed.
    ///
    /// This method takes into account the `Comparability` of the element.
    ///
    /// ## Note
    /// This method may only be called once per layout cycle.
    fileprivate func update(
        with newElement: Element,
        in newEnvironment: Environment,
        identifier: ElementIdentifier
    ) {
        precondition(wasVisited == false)
        precondition(self.identifier == identifier)
        precondition(type(of: newElement) == type(of: element.value))

        let isEquivalent: Bool

        switch comparability {
        case .notComparable:
            isEquivalent = false

        case .comparableElement:
            isEquivalent = Self.elementsEquivalent(
                element.value, newElement,
                in: ComparableElementContext(
                    environment: newEnvironment
                )
            )

        case .childOfComparableElement:
            /// We're always, equivalent, because our parent
            /// determines our equatability from its state.
            /// It will also invalidate and throw away _our_ caches if its
            /// equivalency changes.
            isEquivalent = true
        }

        /// If `isEquivalent` is false, we want to blow away all cached data.
        if isEquivalent == false {
            /// Clear our own cached data.
            clearAllCachedData()

            /// 2) If _we_ are a `ComparableElement`, or children which are `.childOfComparableElement`
            /// depend on us to invalidate their measurements; so do so here. It's important to note
            /// that we only clear child caches if those elements themselves are **not** `ComparableElement`.
            if comparability == .comparableElement {
                recursiveForEach {
                    $0.clearAllCachedDataIfNotComparable()
                }
            }
        } else {

            /// If we are equivalent, we still need to throw out any measurements
            /// and layouts that are dependent on the `Environment`. Compare
            /// the stored `Environment.Subset` values to see if any
            /// of the values that we care about are no longer equivalent.

            measurements.removeAll { _, measurement in
                newEnvironment.valuesEqual(to: measurement.dependencies) == false
            }

            layouts.removeAll { _, layout in
                newEnvironment.valuesEqual(to: layout.dependencies) == false
            }
        }

        /// Update our `ElementSnapshot` to the element's new value.
        /// This will allow cached `LayoutResultNodes` to ensure they
        /// have access to the latest `backingViewDescription`.

        element.value = newElement

        /// If the update was equivalent. Used for debugging.
        wasUpdateEquivalent = isEquivalent

        delegate.perform {
            $0.treeDidUpdateState(self)
        }
    }

    /// Represents a cached measurement, which contains
    /// both the output measurements and the dependencies
    /// from the `Environment`, if any.
    struct CachedMeasurement {
        var size: CGSize
        var dependencies: Environment.Subset?
    }

    /// Invoked by `ElementContent` to generate a measurement via the `measurer`,
    /// or return a cached measurement if one exists.
    func measure(
        in constraint: SizeConstraint,
        with environment: Environment,
        using measurer: (Environment) -> CGSize
    ) -> CGSize {
        /// We already have a cached measurement, reuse that.
        if let existing = measurements[constraint] {
            delegate.perform {
                $0.treeDidReturnCachedMeasurement(existing, for: self)
            }

            return existing.size
        }

        /// Perform the measurement and track the environment dependencies.
        let (size, dependencies) = trackEnvironmentReads(for: .measurement, with: environment, in: measurer)

        /// Save the measurement for next time.

        let measurement = CachedMeasurement(
            size: size,
            dependencies: dependencies
        )

        measurements[constraint] = measurement

        delegate.perform {
            $0.treeDidPerformMeasurement(measurement, for: self)
        }

        return size
    }

    /// Represents a cached `LayoutResultNode` tree of all children,
    /// which contains both child tree, and the dependencies
    /// from the `Environment`, if any.
    struct CachedLayout {
        var nodes: [LayoutResultNode]
        var dependencies: Environment.Subset?
    }

    /// Invoked by `ElementContent` to generate a layout tree via the `layout`,
    /// or return a cached layout tree if one exists.
    func layout(
        in size: CGSize,
        with environment: Environment,
        using layout: (Environment) -> [LayoutResultNode]
    ) -> [LayoutResultNode] {

        /// Layout is only invoked once per cycle. If we're not a `ComparableElement`,
        /// there's no point in caching this value, so just return the `layout` directly.
        guard comparability == .comparableElement else {
            let nodes = layout(environment)

            delegate.perform {
                $0.treeDidPerformLayout(nodes, for: self)
            }

            return nodes
        }

        /// We already have a cached layout, reuse that.
        if let existing = layouts[size] {
            delegate.perform {
                $0.treeDidReturnCachedLayout(existing, for: self)
            }

            return existing.nodes
        }

        /// Perform the layout and track the environment dependencies.
        let (nodes, dependencies) = trackEnvironmentReads(for: .layout, with: environment, in: layout)

        /// Save the layout for next time.

        let layout = CachedLayout(
            nodes: nodes,
            dependencies: dependencies
        )

        layouts[size] = layout

        delegate.perform {
            $0.treeDidPerformCachedLayout(layout, for: self)
        }

        return nodes
    }

    /// Used by measurement and layout to track the dependencies they have on the `Environment`.
    /// The method returns the output from your `toTrack` callback, as well as
    /// an `Environment.Subset` that represents the measurement or layout's dependencies on the `Environment`.
    ///
    /// If there are no dependencies (`toTrack` did not read from the `Environment`), no subset is returned.
    ///
    /// Additionally, if the element is not comparable, no subset is returned or tracked.
    private func trackEnvironmentReads<Output>(
        for layoutPass: Environment.LayoutPass,
        with environment: Environment,
        in toTrack: (Environment) -> Output
    ) -> (Output, Environment.Subset?) {

        switch layoutPass {
        case .measurement:
            if comparability.isComparable {
                break
            } else {
                return (toTrack(environment), nil)
            }
        case .layout:
            if comparability == .comparableElement {
                break
            } else {
                return (toTrack(environment), nil)
            }
        }

        var environment = environment
        var observedKeys = Set<Environment.StorageKey>()

        environment.subscribeToReads(for: layoutPass) { key in
            observedKeys.insert(key)
        }

        let output = toTrack(environment)

        return (output, environment.subset(with: observedKeys))
    }

    /// Creates a new child `ElementState` for the provided `Element`,
    /// or returns an existing one if it already exists.
    ///
    /// The first time the element is seen during a layout traversal, we will call `update`
    /// on its backing `ElementState` to keep internal state in sync.
    func childState(
        for child: Element,
        in environment: Environment,
        with identifier: ElementIdentifier
    ) -> ElementState {

        if let existing = children[identifier] {

            if existing.wasVisited == false {
                orderedChildren.append(existing)
                existing.update(with: child, in: environment, identifier: identifier)
            }

            existing.wasVisited = true

            return existing
        } else {
            let new = ElementState(
                parent: self,
                delegate: delegate,
                identifier: identifier,
                element: child,
                depth: depth + 1,
                signpostRef: signpostRef,
                name: name
            )

            children[identifier] = new

            delegate.perform {
                $0.treeDidCreateState(new)
            }

            return new
        }
    }

    /// To be called at the beginning of the layout cycle by the owner
    /// of the `ElementStateTree`, to set up the tree for a traversal.
    func prepareForLayout() {
        recursiveForEach {
            $0.wasVisited = false
            $0.wasUpdateEquivalent = false

            $0.orderedChildren.removeAll(keepingCapacity: true)
        }
    }

    /// To be called at the end of the layout cycle by the owner
    /// of the `ElementStateTree`, to tear down any old state,
    /// or throw out caches which should not be maintained across layout cycles.
    func finishedLayout() {
        recursiveRemoveOldChildren()
        recursiveClearCaches()
    }

    /// Clears all cached measurements, layouts, etc.
    private func clearAllCachedData() {
        measurements.removeAll()
        layouts.removeAll()
    }

    /// Clears all cached data, but only if the element is **not** a `ComparableElement`.
    private func clearAllCachedDataIfNotComparable() {
        if comparability != .comparableElement {
            clearAllCachedData()
        }
    }

    /// Performs a depth-first enumeration of all elements in the tree,
    /// _including_ the original reciever.
    func recursiveForEach(_ perform: (ElementState) -> Void) {
        perform(self)

        children.forEach { _, child in
            child.recursiveForEach(perform)
        }
    }

    /// Iterating the whole tree, garbage collects all children
    /// which are no longer present in the tree.
    private func recursiveRemoveOldChildren() {

        for (key, state) in children {

            if state.wasVisited { continue }

            children.removeValue(forKey: key)

            delegate.perform {
                $0.treeDidRemoveState(state)
            }
        }

        children.forEach { _, state in
            state.recursiveRemoveOldChildren()
        }
    }

    /// Iterating the whole tree, clears caches which should
    /// not be maintained after the current layout cycle.
    private func recursiveClearCaches() {
        recursiveForEach {
            if $0.comparability.isComparable == false {
                $0.clearAllCachedData()
            }

            /// **TODO:** Should we cache this across layout cycles too? I think no,
            /// because we're already caching layout nodes, so this shouldn't even be called.
            /// But we should verify that!
            $0.cachedContent = nil
        }
    }
}


extension CGSize: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(width)
        hasher.combine(height)
    }
}


/// A token reference type that can be used to group associated signpost logs using `OSSignpostID`.
private final class SignpostToken {}


extension ElementState {

    /// Checks if the two elements are equivalent in the given context.
    ///
    /// - If both values are nil, `true` is returned.
    /// - If both values are different types, `false` is returned.
    static func elementsEquivalent(_ lhs: Element?, _ rhs: Element?, in context: ComparableElementContext) -> Bool {

        if lhs == nil && rhs == nil { return true }

        guard let lhs = lhs as? AnyComparableElement else { return false }
        guard let rhs = rhs as? AnyComparableElement else { return false }

        return lhs.anyIsEquivalent(to: rhs, in: context)
    }
}


extension Dictionary {

    /// Removes all values from the dictionary that pass the provided predicate.
    fileprivate mutating func removeAll(where shouldRemove: (Key, Value) -> Bool) {

        for (key, value) in self {
            if shouldRemove(key, value) {
                removeValue(forKey: key)
            }
        }
    }
}

//
// MARK: ElementStateTreeDelegate
//

/// A delegate object that is called during layout to inspect the actions performed
/// during the layout and measurement process.
protocol ElementStateTreeDelegate: AnyObject {

    /// Root `ElementState`

    func tree(_ tree: ElementStateTree, didSetupRootState state: ElementState)
    func tree(_ tree: ElementStateTree, didUpdateRootState state: ElementState)
    func tree(_ tree: ElementStateTree, didTeardownRootState state: ElementState)
    func tree(_ tree: ElementStateTree, didReplaceRootState state: ElementState, with new: ElementState)

    /// Creating / Updating `ElementState`

    func treeDidCreateState(_ state: ElementState)
    func treeDidUpdateState(_ state: ElementState)
    func treeDidRemoveState(_ state: ElementState)

    func treeDidFetchElementContent(for state: ElementState)

    /// Measuring & Laying Out

    func treeDidReturnCachedMeasurement(
        _ measurement: ElementState.CachedMeasurement,
        for state: ElementState
    )

    func treeDidPerformMeasurement(
        _ measurement: ElementState.CachedMeasurement,
        for state: ElementState
    )

    func treeDidReturnCachedLayout(
        _ layout: ElementState.CachedLayout,
        for state: ElementState
    )

    func treeDidPerformLayout(
        _ layout: [LayoutResultNode],
        for state: ElementState
    )

    func treeDidPerformCachedLayout(
        _ layout: ElementState.CachedLayout,
        for state: ElementState
    )
}


extension Optional where Wrapped == ElementStateTreeDelegate {
    func perform(_ block: (Wrapped) -> Void) {
        #if DEBUG
            if let self = self {
                block(self)
            }
        #endif
    }
}


//
// MARK: CustomDebugStringConvertible
//


extension ElementState: CustomDebugStringConvertible {

    public var debugDescription: String {

        var debugRepresentations = [ElementState.DebugRepresentation]()

        children.values.forEach {
            $0.appendDebugDescriptions(to: &debugRepresentations, at: 0)
        }

        let strings: [String] = debugRepresentations.map { child in
            Array(repeating: "  ", count: child.depth).joined() + child.debugDescription
        }

        let all = ["<ElementState: \(address(of: self))>"] + strings

        return all.joined(separator: "\n")
    }
}


extension ElementState {

    private func appendDebugDescriptions(to: inout [DebugRepresentation], at depth: Int) {

        let info = DebugRepresentation(
            objectIdentifier: ObjectIdentifier(self),
            depth: depth,
            identifier: identifier,
            element: element.value,
            measurements: measurements
        )

        to.append(info)

        children.values.forEach { child in
            child.appendDebugDescriptions(to: &to, at: depth + 1)
        }
    }

    private struct DebugRepresentation: CustomDebugStringConvertible {
        var objectIdentifier: ObjectIdentifier
        var depth: Int
        var identifier: ElementIdentifier
        var element: Element
        var measurements: [SizeConstraint: CachedMeasurement]

        var debugDescription: String {
            "\(type(of: element)) #\(identifier.count): \(measurements.count) Measurements"
        }
    }
}


