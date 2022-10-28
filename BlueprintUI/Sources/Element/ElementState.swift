//
//  ElementState.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 6/24/21.
//

import Foundation
import UIKit


final class RootElementState {

    private(set) var root: ElementState?

    private let signpostRef: SignpostToken = .init()

    let name: String
    var kind: Kind

    init(name: String, kind: Kind) {
        self.name = name
        self.kind = kind
    }

    enum Kind {
        case blueprintView(String)
        case measurement
    }

    func update(with element: Element?, in environment: Environment) {

        func makeRoot(with element: Element) {
            root = ElementState(
                parent: nil,
                identifier: .identifier(for: element, key: nil, count: 1),
                element: element,
                depth: 0,
                signpostRef: signpostRef,
                name: name
            )

            root?.root = self
        }

        if root == nil, let element = element {
            makeRoot(with: element)
        } else if let root = self.root, element == nil {
            root.teardown()
            self.root = nil
        } else if let root = self.root, let element = element {
            if type(of: root.element) == type(of: element) {
                root.update(with: element, in: environment, identifier: root.identifier)
            } else {
                root.teardown()
                makeRoot(with: element)
            }
        }
    }
}


final class ElementState {

    fileprivate(set) weak var root: RootElementState?
    private(set) weak var parent: ElementState?

    let identifier: ElementIdentifier
    let depth: Int
    let signpostRef: AnyObject
    let name: String

    private(set) var element: Element

    let comparability: Comparability

    // TODO: Broken with proxy elements, move to ViewDescription
    private(set) var appliesViewDescriptionIfEquivalent: Bool

    private(set) var wasVisited: Bool
    private(set) var hasUpdatedInCurrentCycle: Bool
    private(set) var wasUpdateEquivalent: Bool

    private var measurements: [SizeConstraint: CachedMeasurement] = [:]
    private var layouts: [CGSize: CachedLayout] = [:]
    private var children: [ElementIdentifier: ElementState] = [:]

    enum Comparability: Equatable {
        /// The element is not comparable, and it is not the child of a comparable element.
        case notComparable
        /// The element is comarable itself.
        case comparableElement
        /// The element is the child of a comparable element, meaning its comparability
        /// is determined by the comparability of that parent element.
        case childOfComparableElement

        var isComparable: Bool {
            switch self {
            case .notComparable: return false
            case .comparableElement: return true
            case .childOfComparableElement: return true
            }
        }
    }

    init(
        parent: ElementState?,
        identifier: ElementIdentifier,
        element: Element,
        depth: Int,
        signpostRef: AnyObject,
        name: String
    ) {
        self.parent = parent
        self.identifier = identifier
        self.element = element

        if let element = element as? AnyComparableElement {
            comparability = .comparableElement
            appliesViewDescriptionIfEquivalent = element.appliesViewDescriptionIfEquivalent
        } else {
            appliesViewDescriptionIfEquivalent = false

            if let parent = parent {
                switch parent.comparability {
                case .notComparable:
                    comparability = .notComparable
                case .comparableElement:
                    comparability = .childOfComparableElement
                case .childOfComparableElement:
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
        hasUpdatedInCurrentCycle = true
        wasUpdateEquivalent = false

        // print("Creating State for \(type(of: element)) \(address(of: self))")
        // print("appliesViewDescriptionIfEquivalent: \(appliesViewDescriptionIfEquivalent)")

    }

    private var cachedContent: ElementContent?

    var elementContent: ElementContent {
        if let cachedContent = cachedContent {
            return cachedContent
        } else {
            let content = element.content
            cachedContent = content
            return content
        }
    }

    fileprivate func update(
        with newElement: Element,
        in newEnvironment: Environment,
        identifier: ElementIdentifier
    ) {
        precondition(self.identifier == identifier)
        precondition(type(of: newElement) == type(of: element))

        let isEquivalent: Bool

        switch comparability {
        case .notComparable:
            isEquivalent = false

        case .comparableElement:
            isEquivalent = Self.elementsEquivalent(element, newElement)

        case .childOfComparableElement:
            /// **Note**: We're equivalent always, because our parent
            /// determines our equatability from its own state.
            isEquivalent = true
        }

        if isEquivalent == false {
            clearAllCachedData()

            if comparability == .comparableElement {
                recursiveForEach {
                    $0.clearAllCachedDataIfNotComparable()
                }
            }
        } else {
            measurements.removeAll { _, measurement in
                newEnvironment.valuesEqual(to: measurement.dependencies) == false
            }

            layouts.removeAll { _, layout in
                newEnvironment.valuesEqual(to: layout.dependencies) == false
            }
        }

        element = newElement

        wasUpdateEquivalent = isEquivalent
        appliesViewDescriptionIfEquivalent = (element as? AnyComparableElement)?.appliesViewDescriptionIfEquivalent ?? true
    }

    func setup() {
        // TODO:
    }

    func teardown() {
        // TODO:
    }

    func findRoot() -> RootElementState? {
        if let parent = parent {
            return parent.findRoot()
        } else {
            return root
        }
    }

    private struct CachedMeasurement {
        var size: CGSize
        var dependencies: Environment.Subset?
    }

    func measure(
        in constraint: SizeConstraint,
        with environment: Environment,
        using measurer: (Environment) -> CGSize
    ) -> CGSize {
        if let existing = measurements[constraint] {
            return existing.size
        }

        let (size, dependencies) = trackEnvironmentReads(with: environment, in: measurer)

        measurements[constraint] = .init(
            size: size,
            dependencies: dependencies
        )

        return size
    }

    private struct CachedLayout {
        var layout: [LayoutResultNode]
        var dependencies: Environment.Subset?
    }

    func layout(
        in size: CGSize,
        with environment: Environment,
        using layout: (Environment) -> [LayoutResultNode]
    ) -> [LayoutResultNode] {

        guard comparability == .comparableElement else {
            return layout(environment)
        }

        if let existing = layouts[size] {
            return existing.layout
        }

        // TODO: Before merge: This should track recursive reads during layout because the layout
        // itself is recursive. Not bothering now for simplicity.

        let (layout, dependencies) = trackEnvironmentReads(with: environment, in: layout)

        layouts[size] = .init(
            layout: layout,
            dependencies: dependencies
        )

        return layout
    }

    private func trackEnvironmentReads<Output>(
        with environment: Environment,
        in toTrack: (Environment) -> Output
    ) -> (Output, Environment.Subset?) {

        guard comparability.isComparable else {
            return (toTrack(environment), nil)
        }

        var environment = environment
        var observedKeys = Set<Environment.StorageKey>()

        environment.onDidRead = { key in
            observedKeys.insert(key)
        }

        let output = toTrack(environment)

        return (output, environment.subset(with: observedKeys))
    }

    func childState(
        for child: Element,
        in environment: Environment,
        with identifier: ElementIdentifier
    ) -> ElementState {

        if let existing = children[identifier] {
            existing.wasVisited = true

            if existing.hasUpdatedInCurrentCycle == false {
                existing.update(with: child, in: environment, identifier: identifier)
                existing.hasUpdatedInCurrentCycle = true
            }

            return existing
        } else {
            let new = ElementState(
                parent: self,
                identifier: identifier,
                element: child,
                depth: depth + 1,
                signpostRef: signpostRef,
                name: name
            )

            children[identifier] = new

            return new
        }
    }

    func viewSizeChanged(from: CGSize, to: CGSize) {

        if from == to { return }

        if let element = self.element as? AnyComparableElement {
            if element.willSizeChangeAffectLayout(from: from, to: to) {
                clearAllCachedData()
            }
        } else {
            clearAllCachedData()
        }

        children.forEach { _, value in
            value.viewSizeChanged(from: from, to: to)
        }
    }

    func prepareForLayout() {
        recursiveForEach {
            $0.wasVisited = false
            $0.hasUpdatedInCurrentCycle = false
            $0.wasUpdateEquivalent = false

            // print("Setting INITIAL to false for \(type(of: $0.element)) \(address(of: $0))")
        }
    }

    func finishedLayout() {
        recursiveRemoveOldChildren()
        recursiveClearCaches()
    }

    private func clearAllCachedData() {
        measurements.removeAll()
        layouts.removeAll()
    }

    private func clearAllCachedDataIfNotComparable() {
        if comparability != .comparableElement {
            clearAllCachedData()
        }
    }

    func recursiveForEach(_ perform: (ElementState) -> Void) {
        perform(self)

        children.forEach { _, child in
            child.recursiveForEach(perform)
        }
    }

    private func recursiveRemoveOldChildren() {

        for (key, state) in children {

            if state.wasVisited { continue }

            state.teardown()

            children.removeValue(forKey: key)
        }

        children.forEach { _, state in
            state.recursiveRemoveOldChildren()
        }
    }

    private func recursiveClearCaches() {
        recursiveForEach {
            if $0.comparability.isComparable == false {
                $0.clearAllCachedData()
            }

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

    static func elementsEquivalent(_ lhs: Element?, _ rhs: Element?) -> Bool {

        if lhs == nil && rhs == nil { return true }

        guard let lhs = lhs as? AnyComparableElement else { return false }
        guard let rhs = rhs as? AnyComparableElement else { return false }

        if lhs.anyIsEquivalent(to: rhs) {
            return true
        } else {
            return false
        }
    }
}


extension Dictionary {

    fileprivate mutating func removeAll(where shouldRemove: (Key, Value) -> Bool) {

        for (key, value) in self {
            if shouldRemove(key, value) {
                print("Removing \(key)")
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
            element: element,
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


