//
//  LayoutPassTestFixture.swift
//
//
//  Created by Kyle Van Essen on 11/3/22.
//

import Foundation
@testable import BlueprintUI

final class LayoutPassTestFixture {

    private(set) var events: [Event] = []

    func removeAll() {
        events.removeAll()
    }
}


extension LayoutPassTestFixture {

    enum Event: Equatable {

        case comparableElement_performedIsEquivalent

        case elementStateTree_didSetupRootState(ElementIdentifier)
        case elementStateTree_didUpdateRootState(ElementIdentifier)
        case elementStateTree_didTeardownRootState(ElementIdentifier)
        case elementStateTree_didReplaceRootState(old: ElementIdentifier, new: ElementIdentifier)

        case elementState_treeDidCreateState(ElementIdentifier)
        case elementState_treeDidUpdateState(ElementIdentifier)
        case elementState_treeDidRemoveState(ElementIdentifier)
        case elementState_treeDidFetchElementContent(ElementIdentifier)

        case elementState_treeDidReturnCachedMeasurement(ElementIdentifier)
        case elementState_treeDidPerformMeasurement(ElementIdentifier)
        case elementState_treeDidReturnCachedLayout(ElementIdentifier)
        case elementState_treeDidPerformLayout(ElementIdentifier)
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
        for state: ElementState
    ) {
        events.append(
            .elementState_treeDidReturnCachedMeasurement(state.identifier)
        )
    }

    func treeDidPerformMeasurement(
        _ measurement: ElementState.CachedMeasurement,
        for state: ElementState
    ) {
        events.append(
            .elementState_treeDidPerformMeasurement(state.identifier)
        )
    }

    func treeDidReturnCachedLayout(
        _ layout: ElementState.CachedLayout,
        for state: ElementState
    ) {
        events.append(
            .elementState_treeDidPerformMeasurement(state.identifier)
        )
    }

    func treeDidPerformLayout(
        _ layout: [LayoutResultNode],
        for state: ElementState
    ) {
        events.append(
            .elementState_treeDidPerformLayout(state.identifier)
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
