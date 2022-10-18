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
                identifier: .init(element: element, key: nil, count: 1),
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

    let isElementComparable: Bool
    private(set) var appliesViewDescriptionIfEquivalent: Bool

    private(set) var wasVisited: Bool
    private(set) var hasUpdatedInCurrentCycle: Bool
    private(set) var wasUpdateEquivalent: Bool

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
        isElementComparable = self.element is AnyComparableElement
        appliesViewDescriptionIfEquivalent = (element as? AnyComparableElement)?.appliesViewDescriptionIfEquivalent ?? true

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

        let isEquivalent: Bool = {
            do {
                return try Self.elementsEquivalent(self.element, newElement)
            } catch {
                guard error is ComparableElementNotEquivalent else {
                    fatalError("Can only throw `ComparableElementNotEquivalent` from `isEquivalent`.")
                }

                return false
            }
        }()

        if isEquivalent == false {
            clearAllCachedData()
        } else {
            measurements.removeAll { _, measurement in
                newEnvironment.valuesEqual(to: measurement.dependencies) == false
            }
        }

        element = newElement

        wasUpdateEquivalent = isEquivalent
        appliesViewDescriptionIfEquivalent = (element as? AnyComparableElement)?.appliesViewDescriptionIfEquivalent ?? true

        // print("Setting `wasUpdateEquivalent` to \(wasUpdateEquivalent) for \(type(of: element))")
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

    private var measurements: [SizeConstraint: CachedMeasurement] = [:]

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

    private func trackEnvironmentReads<Output>(
        with environment: Environment,
        in toTrack: (Environment) -> Output
    ) -> (Output, Environment.Subset?) {
        var environment = environment
        var observedKeys = Set<Environment.StorageKey>()

        environment.onDidRead = { key in
            observedKeys.insert(key)
        }

        let output = toTrack(environment)

        return (output, environment.subset(with: observedKeys))
    }

    private var children: [ElementIdentifier: ElementState] = [:]

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
            if $0.isElementComparable == false {
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

    static func elementsEquivalent(_ lhs: Element?, _ rhs: Element?) throws -> Bool {

        if lhs == nil && rhs == nil { return true }

        guard let lhs = lhs as? AnyComparableElement else { return false }
        guard let rhs = rhs as? AnyComparableElement else { return false }

        if try lhs.anyIsEquivalent(to: rhs) {
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


