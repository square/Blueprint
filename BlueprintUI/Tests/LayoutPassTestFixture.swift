//
//  LayoutPassTestFixture.swift
//
//
//  Created by Kyle Van Essen on 11/3/22.
//

import Foundation
import UIKit
@testable import BlueprintUI

final class LayoutPassTestFixture {

    private(set) var events: [Event] = []

    func removeAll() {
        events.removeAll()
    }
}


extension LayoutPassTestFixture {

    enum Event: Equatable {

        case comparableElement_performedIsEquivalent(ElementIdentifier)

        case elementStateTree_didSetupRootState(ElementIdentifier)
        case elementStateTree_didUpdateRootState(ElementIdentifier)
        case elementStateTree_didTeardownRootState(ElementIdentifier)
        case elementStateTree_didReplaceRootState(old: ElementIdentifier, new: ElementIdentifier)

        case elementState_treeDidCreateState(ElementIdentifier)
        case elementState_treeDidUpdateState(ElementIdentifier)
        case elementState_treeDidRemoveState(ElementIdentifier)
        case elementState_treeDidFetchElementContent(ElementIdentifier)

        case elementState_treeDidReturnCachedMeasurement(ElementIdentifier, SizeConstraint)
        case elementState_treeDidPerformMeasurement(ElementIdentifier, SizeConstraint)
        case elementState_treeDidReturnCachedLayout(ElementIdentifier, CGSize)
        case elementState_treeDidPerformLayout(ElementIdentifier, CGSize)
        case elementState_treeDidPerformCachedLayout(ElementIdentifier)
    }
}


extension LayoutPassTestFixture: ElementStateTreeDelegate {

    /// Root `ElementState`

    func tree(_ tree: ElementStateTree, didSetupRootState state: ElementState) {
        events.append(
            .elementStateTree_didSetupRootState(state.identifier)
        )
    }

    func tree(_ tree: ElementStateTree, didUpdateRootState state: ElementState) {
        events.append(
            .elementStateTree_didUpdateRootState(state.identifier)
        )
    }

    func tree(_ tree: ElementStateTree, didTeardownRootState state: ElementState) {
        events.append(
            .elementStateTree_didTeardownRootState(state.identifier)
        )
    }

    func tree(_ tree: ElementStateTree, didReplaceRootState state: ElementState, with new: ElementState) {
        events.append(
            .elementStateTree_didReplaceRootState(old: state.identifier, new: new.identifier)
        )
    }

    /// Creating / Updating `ElementState`

    func treeDidCreateState(_ state: ElementState) {
        events.append(
            .elementState_treeDidCreateState(state.identifier)
        )
    }

    func treeDidUpdateState(_ state: ElementState) {
        events.append(
            .elementState_treeDidUpdateState(state.identifier)
        )
    }

    func treeDidRemoveState(_ state: ElementState) {
        events.append(
            .elementState_treeDidRemoveState(state.identifier)
        )
    }

    func treeDidFetchElementContent(for state: ElementState) {
        events.append(
            .elementState_treeDidFetchElementContent(state.identifier)
        )
    }

    /// Measuring & Laying Out

    func treeDidReturnCachedMeasurement(
        _ measurement: ElementState.CachedMeasurement,
        constraint: SizeConstraint,
        for state: ElementState
    ) {
        events.append(
            .elementState_treeDidReturnCachedMeasurement(state.identifier, constraint)
        )
    }

    func treeDidPerformMeasurement(
        _ measurement: ElementState.CachedMeasurement,
        constraint: SizeConstraint,
        for state: ElementState
    ) {
        events.append(
            .elementState_treeDidPerformMeasurement(state.identifier, constraint)
        )
    }

    func treeDidReturnCachedLayout(
        _ layout: ElementState.CachedLayout,
        size: CGSize,
        for state: ElementState
    ) {
        events.append(
            .elementState_treeDidReturnCachedLayout(state.identifier, size)
        )
    }

    func treeDidPerformLayout(
        _ layout: [LayoutResultNode],
        size: CGSize,
        for state: ElementState
    ) {
        events.append(
            .elementState_treeDidPerformLayout(state.identifier, size)
        )
    }

    func treeDidPerformCachedLayout(
        _ layout: ElementState.CachedLayout,
        for state: ElementState
    ) {
        events.append(
            .elementState_treeDidPerformCachedLayout(state.identifier)
        )
    }
}


/// By using `print(fixture.element)`, you can get
/// a list of events to place into your code when writing integration tests.
extension Array where Element == LayoutPassTestFixture.Event {

    var swiftStringRepresentation: String {
        map(\.swiftStringRepresentation).joined(separator: ",\n")
    }
}


/// By using `print(identifiers)`, you can get
/// a list of identifiers to place into your code when writing tests.
extension Array where Element == ElementIdentifier {

    func swiftStringRepresentation(inferredType: Bool) -> String {
        map {
            $0.swiftStringRepresentation(inferredType: inferredType)
        }
        .joined(separator: ",\n")
    }
}


extension ElementIdentifier {

    func swiftStringRepresentation(inferredType: Bool) -> String {

        let elementName = String(describing: elementType)
        let key = String(describing: key)
        let count = String(describing: count)

        return "\(inferredType ? "" : "ElementIdentifier").identifier(for: \(elementName).self, key: \(key), count: \(count))"
    }
}

extension SizeConstraint {
    fileprivate var swiftStringRepresentation: String {
        "SizeConstraint(width: \(width.swiftStringRepresentation), height: \(height.swiftStringRepresentation))"
    }
}

extension CGSize {
    fileprivate var swiftStringRepresentation: String {
        "CGSize(width: \(width), height: \(height))"
    }
}

extension SizeConstraint.Axis {
    fileprivate var swiftStringRepresentation: String {
        switch self {
        case .atMost(let max):
            return ".atMost(\(max))"
        case .unconstrained:
            return ".unconstrained"
        }
    }
}

extension LayoutPassTestFixture.Event {

    fileprivate var swiftStringRepresentation: String {

        func caseString(named: String, parameters: [(name: String, content: String)]) -> String {

            let parameters: [String] = parameters.map { name, content in

                if name.isEmpty == false {
                    return "\(name): \(content)"
                } else {
                    return content
                }
            }

            if parameters.isEmpty == false {
                return ".\(named)(\(parameters.joined(separator: ", ")))"
            } else {
                return named
            }
        }

        func caseString(named: String, id: ElementIdentifier) -> String {
            caseString(named: named, parameters: [
                (name: "", content: id.swiftStringRepresentation(inferredType: true)),
            ])
        }

        switch self {
        case .comparableElement_performedIsEquivalent(let id):
            return caseString(named: "comparableElement_performedIsEquivalent", id: id)
        case .elementStateTree_didSetupRootState(let id):
            return caseString(named: "elementStateTree_didSetupRootState", id: id)
        case .elementStateTree_didUpdateRootState(let id):
            return caseString(named: "elementStateTree_didUpdateRootState", id: id)
        case .elementStateTree_didTeardownRootState(let id):
            return caseString(named: "elementStateTree_didTeardownRootState", id: id)
        case .elementStateTree_didReplaceRootState(let old, let new):
            let old = old.swiftStringRepresentation(inferredType: true)
            let new = new.swiftStringRepresentation(inferredType: true)
            return ".elementStateTree_didReplaceRootState(old: \(old), new: \(new))"
        case .elementState_treeDidCreateState(let id):
            return caseString(named: "elementState_treeDidCreateState", id: id)
        case .elementState_treeDidUpdateState(let id):
            return caseString(named: "elementState_treeDidUpdateState", id: id)
        case .elementState_treeDidRemoveState(let id):
            return caseString(named: "elementState_treeDidRemoveState", id: id)
        case .elementState_treeDidFetchElementContent(let id):
            return caseString(named: "elementState_treeDidFetchElementContent", id: id)
        case .elementState_treeDidReturnCachedMeasurement(let id, let constraint):
            return caseString(named: "elementState_treeDidReturnCachedMeasurement", parameters: [
                (name: "", content: id.swiftStringRepresentation(inferredType: true)),
                (name: "", content: constraint.swiftStringRepresentation),
            ])
        case .elementState_treeDidPerformMeasurement(let id, let constraint):
            return caseString(named: "elementState_treeDidPerformMeasurement", parameters: [
                (name: "", content: id.swiftStringRepresentation(inferredType: true)),
                (name: "", content: constraint.swiftStringRepresentation),
            ])
        case .elementState_treeDidReturnCachedLayout(let id, let size):
            return caseString(named: "elementState_treeDidReturnCachedLayout", parameters: [
                (name: "", content: id.swiftStringRepresentation(inferredType: true)),
                (name: "", content: size.swiftStringRepresentation),
            ])
        case .elementState_treeDidPerformLayout(let id, let size):
            return caseString(named: "elementState_treeDidPerformLayout", parameters: [
                (name: "", content: id.swiftStringRepresentation(inferredType: true)),
                (name: "", content: size.swiftStringRepresentation),
            ])
        case .elementState_treeDidPerformCachedLayout(let id):
            return caseString(named: "elementState_treeDidPerformCachedLayout", id: id)
        }
    }
}
