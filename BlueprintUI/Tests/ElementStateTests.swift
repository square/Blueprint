// swiftformat:disable redundantReturn
//
//  ElementStateTests.swift
//
//
//  Created by Kyle Van Essen on 11/3/22.
//

import Foundation
import XCTest
@testable import BlueprintUI


extension ElementStateTree {

    func performLayout(
        with element: Element,
        with size: CGSize = UIScreen.main.bounds.size,
        in environment: Environment = .empty
    ) -> ElementState {

        XCTAssertNotEqual(size, .zero, "Layout size cannot be zero.")

        let (state, _) = performUpdate(with: element, in: environment) { state in
            state.elementContent.performLayout(in: size, with: environment, state: state)
        }

        return state
    }
}


class ElementStateTreeTests: XCTestCase {

    func test_integration() {

        // Verify that updating a BlueprintView's state tree round trips correctly.

        let fixture = LayoutPassTestFixture()
        let blueprintView = BlueprintView(frame: .init(origin: .zero, size: .init(width: 100, height: 200)))
        blueprintView.rootState.delegate = fixture

        let element1 = Empty()

        let element2 = Row(alignment: .fill) {
            Column(alignment: .fill) {
                Empty()
            }

            Column(alignment: .fill) {}
        }

        let element3 = Column(alignment: .fill) {
            Row(alignment: .fill) {
                Empty()
            }
        }

        blueprintView.element = element1
        blueprintView.layoutIfNeeded()

        XCTAssertEqual(
            blueprintView.rootState.identifierTree,
            IdentifiedNode(Empty.identifier(1))
        )

        XCTAssertEqual(fixture.events, [
            .elementStateTree_didSetupRootState(.identifier(for: Empty.self, key: nil, count: 1)),
        ])

        fixture.removeAll()

        blueprintView.element = element2
        blueprintView.layoutIfNeeded()

        XCTAssertEqual(
            blueprintView.rootState.identifierTree,
            IdentifiedNode(Row.identifier(1)) {
                IdentifiedNode(Column.identifier(1)) {
                    IdentifiedNode(Empty.identifier(1))
                }

                IdentifiedNode(Column.identifier(2))
            }
        )

        XCTAssertEqual(fixture.events, [
            .elementStateTree_didReplaceRootState(
                old: .identifier(for: Empty.self, key: nil, count: 1),
                new: .identifier(for: Row.self, key: nil, count: 1)
            ),
            .elementState_treeDidCreateState(.identifier(for: Column.self, key: nil, count: 1)),
            .elementState_treeDidCreateState(.identifier(for: Column.self, key: nil, count: 2)),
            .elementState_treeDidFetchElementContent(.identifier(for: Column.self, key: nil, count: 1)),
            .elementState_treeDidCreateState(.identifier(for: Empty.self, key: nil, count: 1)),
            .elementState_treeDidFetchElementContent(.identifier(for: Empty.self, key: nil, count: 1)),
            .elementState_treeDidPerformMeasurement(
                .identifier(for: Empty.self, key: nil, count: 1),
                SizeConstraint(width: .atMost(100.0), height: .atMost(200.0))
            ),
            .elementState_treeDidPerformMeasurement(
                .identifier(for: Empty.self, key: nil, count: 1),
                SizeConstraint(width: .atMost(100.0), height: .atMost(0.0))
            ),
            .elementState_treeDidPerformMeasurement(
                .identifier(for: Column.self, key: nil, count: 1),
                SizeConstraint(width: .atMost(100.0), height: .atMost(200.0))
            ),
            .elementState_treeDidFetchElementContent(.identifier(for: Column.self, key: nil, count: 2)),
            .elementState_treeDidPerformMeasurement(
                .identifier(for: Column.self, key: nil, count: 2),
                SizeConstraint(width: .atMost(100.0), height: .atMost(200.0))
            ),
            .elementState_treeDidPerformMeasurement(
                .identifier(for: Empty.self, key: nil, count: 1),
                SizeConstraint(width: .atMost(0.0), height: .atMost(200.0))
            ),
            .elementState_treeDidPerformLayout(
                .identifier(for: Column.self, key: nil, count: 1),
                CGSize(width: 0.0, height: 200.0)
            ),
            .elementState_treeDidPerformLayout(
                .identifier(for: Row.self, key: nil, count: 1),
                CGSize(width: 100.0, height: 200.0)
            ),
        ])

        fixture.removeAll()

        blueprintView.element = element3
        blueprintView.layoutIfNeeded()

        XCTAssertEqual(
            blueprintView.rootState.identifierTree,
            IdentifiedNode(Column.identifier(1)) {
                IdentifiedNode(Row.identifier(1)) {
                    IdentifiedNode(Empty.identifier(1))
                }
            }
        )

        XCTAssertEqual(fixture.events, [
            .elementStateTree_didReplaceRootState(
                old: .identifier(for: Row.self, key: nil, count: 1),
                new: .identifier(for: Column.self, key: nil, count: 1)
            ),
            .elementState_treeDidCreateState(.identifier(for: Row.self, key: nil, count: 1)),
            .elementState_treeDidFetchElementContent(.identifier(for: Row.self, key: nil, count: 1)),
            .elementState_treeDidCreateState(.identifier(for: Empty.self, key: nil, count: 1)),
            .elementState_treeDidFetchElementContent(.identifier(for: Empty.self, key: nil, count: 1)),
            .elementState_treeDidPerformMeasurement(
                .identifier(for: Empty.self, key: nil, count: 1),
                SizeConstraint(width: .atMost(100.0), height: .atMost(200.0))
            ),
            .elementState_treeDidPerformMeasurement(
                .identifier(for: Empty.self, key: nil, count: 1),
                SizeConstraint(width: .atMost(0.0), height: .atMost(200.0))
            ),
            .elementState_treeDidPerformMeasurement(
                .identifier(for: Row.self, key: nil, count: 1),
                SizeConstraint(width: .atMost(100.0), height: .atMost(200.0))
            ),
            .elementState_treeDidPerformMeasurement(
                .identifier(for: Empty.self, key: nil, count: 1),
                SizeConstraint(width: .atMost(100.0), height: .atMost(0.0))
            ),
            .elementState_treeDidPerformLayout(
                .identifier(for: Row.self, key: nil, count: 1),
                CGSize(width: 100.0, height: 0.0)
            ),
            .elementState_treeDidPerformLayout(
                .identifier(for: Column.self, key: nil, count: 1),
                CGSize(width: 100.0, height: 200.0)
            ),
        ])

        fixture.removeAll()

        blueprintView.element = nil
        blueprintView.layoutIfNeeded()

        XCTAssertEqual(
            blueprintView.rootState.identifierTree,
            nil
        )

        XCTAssertEqual(fixture.events, [
            .elementStateTree_didTeardownRootState(.identifier(for: Column.self, key: nil, count: 1)),
        ])
    }

    func test_layout_caching_updates_elements() throws {

        struct OuterTestElement: ProxyElement, ComparableElement {

            var innerValue: Int

            var elementRepresentation: Element {
                Column {
                    Row {
                        InnerTestElement(value: innerValue)
                        InnerTestElement(value: innerValue + 1)
                    }
                }
            }

            func isEquivalent(to other: OuterTestElement) -> Bool {
                true
            }
        }

        struct InnerTestElement: ProxyElement, Equatable {
            var value: Int

            var elementRepresentation: Element {
                Empty()
            }
        }

        let blueprintView = BlueprintView(frame: .init(origin: .zero, size: .init(width: 100, height: 200)))

        blueprintView.element = OuterTestElement(innerValue: 1)
        blueprintView.layoutIfNeeded()

        let state = try XCTUnwrap(blueprintView.rootState.root)

        XCTAssertEqual(
            state.orderedChildren[0].orderedChildren[0].element.latest as! InnerTestElement,
            InnerTestElement(value: 1)
        )
        XCTAssertEqual(
            state.orderedChildren[0].orderedChildren[1].element.latest as! InnerTestElement,
            InnerTestElement(value: 2)
        )

        blueprintView.element = OuterTestElement(innerValue: 3)
        blueprintView.layoutIfNeeded()

        XCTAssertEqual(
            state.orderedChildren[0].orderedChildren[0].element.latest as! InnerTestElement,
            InnerTestElement(value: 3)
        )
        XCTAssertEqual(
            state.orderedChildren[0].orderedChildren[1].element.latest as! InnerTestElement,
            InnerTestElement(value: 4)
        )
    }

    func test_performUpdate() throws {

        let fixture = LayoutPassTestFixture()
        let tree = ElementStateTree(name: "Testing")
        tree.delegate = fixture

        let element1 = Element1(text: "1")
        let element1b = Element1(text: "1.1")
        let element2 = Element2(text: "2")

        XCTAssertNil(tree.root)

        // Initial update should create a state.

        _ = tree.performUpdate(with: element1, in: .empty) { _ in }

        let state1 = try XCTUnwrap(tree.root)

        XCTAssertEqual((state1.element.latest as! Element1).text, "1")

        // Updating with the same element of the same type should keep the same state.

        _ = tree.performUpdate(with: element1b, in: .empty) { _ in }

        let state2 = try XCTUnwrap(tree.root)

        XCTAssertTrue(state1 === state2)

        // Also make sure that we actually update the contained element.

        XCTAssertEqual((state1.element.latest as! Element1).text, "1.1")

        // Updating with a new type should tear down the state.

        _ = tree.performUpdate(with: element2, in: .empty) { _ in }

        let state3 = try XCTUnwrap(tree.root)

        XCTAssertFalse(state2 === state3)

        // Updating with nil should tear down the state.

        _ = tree.teardownRootElement()

        XCTAssertNil(tree.root)

        XCTAssertEqual(fixture.events, [
            .elementStateTree_didSetupRootState(.identifier(for: Element1.self, key: nil, count: 1)),
            .elementState_treeDidUpdateState(.identifier(for: Element1.self, key: nil, count: 1)),
            .elementStateTree_didUpdateRootState(.identifier(for: Element1.self, key: nil, count: 1)),
            .elementStateTree_didReplaceRootState(
                old: .identifier(for: Element1.self, key: nil, count: 1),
                new: .identifier(for: Element2.self, key: nil, count: 1)
            ),
            .elementStateTree_didTeardownRootState(.identifier(for: Element2.self, key: nil, count: 1)),
        ])
    }
}


class ElementStateTests: XCTestCase {

    func test_init() {

        testcase("default property values") {
            let state = ElementState(
                parent: nil,
                delegate: nil,
                identifier: .identifier(for: Element1.self, key: nil, count: 1),
                element: Element1(text: "1"),
                signpostRef: NSObject(),
                name: ""
            )

            XCTAssertTrue(state.wasVisited)
            XCTAssertTrue(state.hasUpdatedChildrenDuringLayout)
        }

        // TODO: additional codepaths testing.
    }

    func test_elementContent() {
        // TODO:
    }

    func test_measure() {
        // TODO:
    }

    func test_layout() {
        // TODO:
    }

    func test_childState() throws {
        let delegate = TestDelegate()

        let root = Element1(text: "root")
        let child1 = Element1(text: "child1")
        let child2 = Element1(text: "child2")

        let tree = ElementStateTree(name: "test")
        tree.delegate = delegate
        let env = Environment.empty

        XCTAssertEqual(0, delegate.didSetupRootCalls.count)
        XCTAssertEqual(0, delegate.didUpdateRootCalls.count)

        _ = tree.performUpdate(with: root, in: env) { _ in }

        let rootState = try XCTUnwrap(tree.root)
        XCTAssertTrue(rootState === delegate.didSetupRootCalls[0])

        let childState1 = try XCTUnwrap(rootState.childState(for: child1, in: env, with: child1.identifier))
        XCTAssertTrue(childState1 === delegate.didCreateStateCalls[0])

        let childState2 = try XCTUnwrap(childState1.childState(for: child2, in: env, with: child2.identifier))
        XCTAssertTrue(childState2 === delegate.didCreateStateCalls[1])

        XCTAssertNil(rootState.parent)
        XCTAssertEqual(ObjectIdentifier(childState1.parent!), ObjectIdentifier(rootState))
        XCTAssertEqual(ObjectIdentifier(childState2.parent!), ObjectIdentifier(childState1))
    }

    func test_recursiveForEach() throws {
        let root = Element1(text: "root")
        let child1 = Element1(text: "child1")
        let child2 = Element1(text: "child2")

        let tree = ElementStateTree(name: "test")
        let env = Environment.empty

        _ = tree.performUpdate(with: root, in: env) { _ in }

        let rootState = try XCTUnwrap(tree.root)
        let childState1 = try XCTUnwrap(rootState.childState(for: child1, in: env, with: child1.identifier))
        let childState2 = try XCTUnwrap(childState1.childState(for: child2, in: env, with: child2.identifier))

        let expectedOrder = [rootState, childState1, childState2]

        var count = 0
        rootState.recursiveForEach { state in
            XCTAssertEqual(ObjectIdentifier(expectedOrder[count]), ObjectIdentifier(state))
            count += 1
        }

        XCTAssertEqual(3, count)
    }
}


class ElementStateTree_IdentifierTree_Tests: XCTestCase {

    func test_identifierTree() {

        let tree = ElementStateTree(name: "Testing")

        XCTAssertEqual(tree.identifierTree, nil)

        let element = Row {
            Column {
                Empty()
            }

            Column {
                Empty()
                Empty()
            }
        }

        _ = tree.performLayout(with: element)

        XCTAssertEqual(
            tree.identifierTree,
            IdentifiedNode(Row.identifier(1)) {
                IdentifiedNode(Column.identifier(1)) {
                    IdentifiedNode(Empty.identifier(1))
                }

                IdentifiedNode(Column.identifier(2)) {
                    IdentifiedNode(Empty.identifier(1))
                    IdentifiedNode(Empty.identifier(2))
                }
            }
        )
    }
}


extension Element {

    fileprivate static func identifier(_ count: Int) -> ElementIdentifier {
        .identifier(for: self, key: nil, count: count)
    }
}


fileprivate struct Element1: ProxyElement {

    var text: String

    var elementRepresentation: Element {
        Empty()
    }
}


fileprivate struct Element2: ProxyElement {

    var text: String

    var elementRepresentation: Element {
        Empty()
    }
}


fileprivate struct EquatableElement1: ProxyElement, ComparableElement, Equatable {

    var text: String

    var elementRepresentation: Element {
        Empty()
    }
}


fileprivate struct EquatableElement2: ProxyElement, ComparableElement, Equatable {

    var text: String

    var elementRepresentation: Element {
        Empty()
    }
}

/// Test element that can have children for building a hierarchy/tree of `Element`
fileprivate struct ContainerElement: Element {

    struct MockLayout: Layout {
        func measure(in constraint: BlueprintUI.SizeConstraint, items: [(traits: (), content: BlueprintUI.Measurable)]) -> CGSize {
            CGSize.zero
        }

        func layout(size: CGSize, items: [(traits: (), content: BlueprintUI.Measurable)]) -> [BlueprintUI.LayoutAttributes] {
            []
        }
    }

    private var children: [Element] = []

    var content: BlueprintUI.ElementContent {
        ElementContent(layout: MockLayout()) { builder in
            children.forEach { builder.add(element: $0) }
        }
    }

    public init() {}

    public init(_ configure: (inout Self) -> Void) {
        self.init()
        configure(&self)
    }

    public mutating func add(_ child: Element) {
        children.append(child)
    }

    func backingViewDescription(with context: BlueprintUI.ViewDescriptionContext) -> BlueprintUI.ViewDescription? {
        nil
    }
}

fileprivate final class TestDelegate: ElementStateTreeDelegate {

    var didSetupRootCalls: [ElementState] = []
    var didUpdateRootCalls: [ElementState] = []
    var didTeardownRootCalls: [ElementState] = []
    var didReplaceRootCalls: [ElementState] = []
    var didCreateStateCalls: [ElementState] = []
    var didUpdateStateCalls: [ElementState] = []
    var didRemoveStateCalls: [ElementState] = []

    func tree(_ tree: BlueprintUI.ElementStateTree, didSetupRootState state: BlueprintUI.ElementState) {
        didSetupRootCalls.append(state)
    }

    func tree(_ tree: BlueprintUI.ElementStateTree, didUpdateRootState state: BlueprintUI.ElementState) {
        didUpdateRootCalls.append(state)
    }

    func tree(_ tree: BlueprintUI.ElementStateTree, didTeardownRootState state: BlueprintUI.ElementState) {
        didTeardownRootCalls.append(state)
    }

    func tree(
        _ tree: BlueprintUI.ElementStateTree,
        didReplaceRootState state: BlueprintUI.ElementState,
        with new: BlueprintUI.ElementState
    ) {
        didReplaceRootCalls.append(state)
    }

    func treeDidCreateState(_ state: BlueprintUI.ElementState) {
        didCreateStateCalls.append(state)
    }

    func treeDidUpdateState(_ state: BlueprintUI.ElementState) {
        didUpdateStateCalls.append(state)
    }

    func treeDidRemoveState(_ state: BlueprintUI.ElementState) {
        didRemoveStateCalls.append(state)
    }

    func treeDidFetchElementContent(for state: BlueprintUI.ElementState) {}

    func treeDidReturnCachedMeasurement(
        _ measurement: BlueprintUI.ElementState.CachedMeasurement,
        constraint: SizeConstraint,
        for state: BlueprintUI.ElementState
    ) {}

    func treeDidPerformMeasurement(
        _ measurement: BlueprintUI.ElementState.CachedMeasurement,
        constraint: SizeConstraint,
        for state: BlueprintUI.ElementState
    ) {}

    func treeDidReturnCachedLayout(
        _ layout: BlueprintUI.ElementState.CachedLayout,
        size: CGSize,
        for state: BlueprintUI.ElementState
    ) {}

    func treeDidPerformLayout(
        _ layout: [BlueprintUI.LayoutResultNode],
        size: CGSize,
        for state: BlueprintUI.ElementState
    ) {}

    func treeDidPerformCachedLayout(_ layout: BlueprintUI.ElementState.CachedLayout, for state: BlueprintUI.ElementState) {}
}


struct IdentifiedNode: Hashable {
    var identifier: ElementIdentifier

    var children: [IdentifiedNode]

    init(
        _ identifier: ElementIdentifier,
        @Builder<IdentifiedNode> children: () -> [IdentifiedNode] = { [] }
    ) {
        self.identifier = identifier
        self.children = children()
    }
}


extension ElementStateTree {

    var identifierTree: IdentifiedNode? {
        root?.identifiedNode
    }
}


extension ElementState {

    var identifiedNode: IdentifiedNode {
        .init(
            identifier,
            children: { orderedChildren.map(\.identifiedNode) }
        )
    }
}


extension Element {
    var identifier: ElementIdentifier {
        .identifier(for: self, key: nil, count: 1)
    }
}
