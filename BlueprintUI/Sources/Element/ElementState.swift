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

    /// A human readable name that represents the tree. Useful for debugging.
    let name: String

    init(name: String) {
        self.name = name
    }

    /// Updates, replaces, or removes the root node depending on the type of the new element.
    func update(with element: Element?, in environment: Environment) {

        func makeRoot(with element: Element) {
            root = ElementState(
                parent: nil,
                identifier: .init(elementType: type(of: element), key: nil, count: 1),
                element: element,
                signpostRef: signpostRef,
                name: name
            )
        }

        if root == nil, let element = element {
            /// Transition from no root element, to root element.
            makeRoot(with: element)
        } else if root != nil, element == nil {
            /// Transition from a root element, to no root element.
            root = nil
        } else if let root = root, let element = element {
            if type(of: root.element.value) == type(of: element) {
                /// The type of the new element is the same, update inline.
                root.update(with: element, in: environment, identifier: root.identifier)
            } else {
                /// The type of the root element changed, replace it.
                makeRoot(with: element)
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

    /// The identifier of the element. Eg, `Inset.1` or `Inset.1.Key`.
    let identifier: ElementIdentifier

    /// The signpost ref used when logging to `os_log`.
    let signpostRef: AnyObject

    /// The name of the owning tree. Useful for debugging.
    let name: String

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
        identifier: ElementIdentifier,
        element: Element,
        signpostRef: AnyObject,
        name: String
    ) {
        self.parent = parent
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
    }

    /// Represents a cached measurement, which contains
    /// both the output measurements and the dependencies
    /// from the `Environment`, if any.
    private struct CachedMeasurement {
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
            return existing.size
        }

        /// Perform the measurement and track the environment dependencies.
        let (size, dependencies) = trackEnvironmentReads(for: .measurement, with: environment, in: measurer)

        /// Save the measurement for next time.
        measurements[constraint] = .init(
            size: size,
            dependencies: dependencies
        )

        return size
    }

    /// Represents a cached `LayoutResultNode` tree of all children,
    /// which contains both child tree, and the dependencies
    /// from the `Environment`, if any.
    private struct CachedLayout {
        var layout: [LayoutResultNode]
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
            return layout(environment)
        }

        /// We already have a cached layout, reuse that.
        if let existing = layouts[size] {
            return existing.layout
        }

        /// Perform the layout and track the environment dependencies.
        let (layout, dependencies) = trackEnvironmentReads(for: .layout, with: environment, in: layout)

        /// Save the layout for next time.
        layouts[size] = .init(
            layout: layout,
            dependencies: dependencies
        )

        return layout
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
                existing.update(with: child, in: environment, identifier: identifier)
            }

            existing.wasVisited = true

            return existing
        } else {
            let new = ElementState(
                parent: self,
                identifier: identifier,
                element: child,
                signpostRef: signpostRef,
                name: name
            )

            children[identifier] = new

            return new
        }
    }

    /// To be called at the beginning of the layout cycle by the owner
    /// of the `ElementStateTree`, to set up the tree for a traversal.
    func prepareForLayout() {
        recursiveForEach {
            $0.wasVisited = false
            $0.wasUpdateEquivalent = false
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


