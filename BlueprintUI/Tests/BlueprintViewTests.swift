import XCTest
@testable import BlueprintUI

class BlueprintViewTests: XCTestCase {

    func test_sizeThatFits() {

        /// NOTE: References to `.greatestFiniteMagnitude` always refer to the fully qualified type,
        /// `CGFloat.greatestFiniteMagnitude` to ensure we are not implicitly comparing against doubles,
        /// which have a different underlying type on 32 bit devices.

        let blueprintView = BlueprintView()

        // Normal sizes.

        do {
            let element = MeasurableElement { constraint in
                XCTAssertEqual(constraint.maximum, CGSize(width: 200, height: 100))
                return CGSize(width: 100, height: 50)
            }

            blueprintView.element = element

            XCTAssertEqual(blueprintView.sizeThatFits(CGSize(width: 200, height: 100)), CGSize(width: 100, height: 50))
        }

        // Unconstrained in both axes.

        do {
            let element = MeasurableElement { constraint in
                XCTAssertEqual(constraint.width, .unconstrained)
                XCTAssertEqual(constraint.height, .unconstrained)
                XCTAssertEqual(
                    constraint.maximum,
                    CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
                )

                return CGSize(width: 100, height: 50)
            }

            blueprintView.element = element

            XCTAssertEqual(blueprintView.sizeThatFits(.zero), CGSize(width: 100, height: 50))
            XCTAssertEqual(
                blueprintView.sizeThatFits(CGSize(
                    width: CGFloat.greatestFiniteMagnitude,
                    height: CGFloat.greatestFiniteMagnitude
                )),
                CGSize(width: 100, height: 50)
            )
            XCTAssertEqual(
                blueprintView.sizeThatFits(CGSize(width: CGFloat.infinity, height: CGFloat.infinity)),
                CGSize(width: 100, height: 50)
            )
        }

        // Unconstrained in one axis only.

        do {
            // X

            do {
                let element = MeasurableElement { constraint in
                    XCTAssertEqual(constraint.width, .unconstrained)
                    XCTAssertEqual(constraint.height.maximum, 100.0)
                    XCTAssertEqual(constraint.maximum, CGSize(width: CGFloat.greatestFiniteMagnitude, height: 100.0))

                    return CGSize(width: 100, height: 50)
                }

                blueprintView.element = element

                XCTAssertEqual(
                    blueprintView.sizeThatFits(CGSize(width: 0.0, height: 100.0)),
                    CGSize(width: 100, height: 50)
                )
                XCTAssertEqual(
                    blueprintView.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: 100.0)),
                    CGSize(width: 100, height: 50)
                )
                XCTAssertEqual(
                    blueprintView.sizeThatFits(CGSize(width: CGFloat.infinity, height: 100.0)),
                    CGSize(width: 100, height: 50)
                )
            }

            // Y

            do {
                let element = MeasurableElement { constraint in
                    XCTAssertEqual(constraint.width.maximum, 100.0)
                    XCTAssertEqual(constraint.height, .unconstrained)
                    XCTAssertEqual(constraint.maximum, CGSize(width: 100.0, height: CGFloat.greatestFiniteMagnitude))

                    return CGSize(width: 100, height: 50)
                }

                blueprintView.element = element

                XCTAssertEqual(
                    blueprintView.sizeThatFits(CGSize(width: 100.0, height: 0.0)),
                    CGSize(width: 100, height: 50)
                )
                XCTAssertEqual(
                    blueprintView.sizeThatFits(CGSize(width: 100.0, height: CGFloat.greatestFiniteMagnitude)),
                    CGSize(width: 100, height: 50)
                )
                XCTAssertEqual(
                    blueprintView.sizeThatFits(CGSize(width: 100.0, height: CGFloat.infinity)),
                    CGSize(width: 100, height: 50)
                )
            }
        }
    }

    func test_displaysSimpleView() {

        let blueprintView = BlueprintView(element: SimpleViewElement(color: .red))

        XCTAssert(UIView.self == type(of: blueprintView.currentNativeViewControllers[0].node.view))
        XCTAssertEqual(blueprintView.currentNativeViewControllers[0].node.view.frame, blueprintView.bounds)
    }

    func test_updatesExistingViews() {
        let blueprintView = BlueprintView(element: SimpleViewElement(color: .green))

        let initialView = blueprintView.currentNativeViewControllers[0].node.view
        XCTAssertEqual(initialView.backgroundColor, UIColor.green)

        blueprintView.element = SimpleViewElement(color: .blue)

        XCTAssert(initialView === blueprintView.currentNativeViewControllers[0].node.view)
        XCTAssertEqual(initialView.backgroundColor, UIColor.blue)
    }

    func test_viewOrder() {
        let blueprintView = BlueprintView()

        var tags: [Int]

        blueprintView.element = TestContainer(
            children: [
                TestElement1(tag: 1),
                TestElement1(tag: 2),
            ]
        )

        tags = [1, 2]
        for index in blueprintView.currentNativeViewControllers.indices {
            let node = blueprintView.currentNativeViewControllers[index].node

            let viewAtIndex = node.view.superview!.subviews[index]
            XCTAssertEqual(node.view, viewAtIndex)
            XCTAssertEqual(node.view.tag, tags[index])
        }

        blueprintView.element = TestContainer(
            children: [
                TestElement2(tag: 3),
                TestElement1(tag: 4),
            ]
        )

        tags = [3, 4]
        for index in blueprintView.currentNativeViewControllers.indices {
            let node = blueprintView.currentNativeViewControllers[index].node

            let viewAtIndex = node.view.superview!.subviews[index]
            XCTAssertEqual(node.view, viewAtIndex)
            XCTAssertEqual(node.view.tag, tags[index])
        }
    }

    func test_nil_element() {

        let view = BlueprintView()
        view.layoutIfNeeded()

        XCTAssertNil(view.element)
        XCTAssertEqual(view.needsViewHierarchyUpdate, false)

        view.element = nil
        XCTAssertEqual(view.needsViewHierarchyUpdate, false)
    }

    func test_recursiveLayout() {
        let view = BlueprintView()

        var layoutRecursed = false

        func onLayoutSubviews() {
            layoutRecursed = true
        }

        struct TestElement: Element {
            var onLayoutSubviews: () -> Void

            var content: ElementContent {
                ElementContent(intrinsicSize: .zero)
            }

            func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
                TestView.describe { config in
                    config.apply { view in
                        // make sure UIKit knows we want a chance for layout
                        view.setNeedsLayout()
                    }
                    config[\.onLayoutSubviews] = self.onLayoutSubviews
                }
            }

            class TestView: UIView {
                var onLayoutSubviews: (() -> Void)?

                override func layoutSubviews() {
                    super.layoutSubviews()
                    onLayoutSubviews?()
                }
            }
        }

        view.element = TestElement(onLayoutSubviews: onLayoutSubviews)

        // trigger a layout pass
        _ = view.currentNativeViewControllers

        XCTAssertTrue(layoutRecursed)
    }

    func test_baseEnvironment() {
        enum TestValue {
            case defaultValue
            case right
        }

        struct TestKey: EnvironmentKey {
            static var defaultValue: TestValue = .defaultValue
        }

        let view = BlueprintView()

        var environment = Environment.empty
        environment[TestKey.self] = .right
        view.environment = environment

        var value: TestValue = .defaultValue

        func updateValue(new: TestValue) {
            value = new
        }

        struct TestElement: Element {
            var updateValue: (TestValue) -> Void

            var content: ElementContent {
                ElementContent(intrinsicSize: .zero)
            }

            func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
                updateValue(context.environment[TestKey.self])
                return nil
            }
        }

        view.element = TestElement(updateValue: updateValue)

        // trigger a layout pass
        _ = view.currentNativeViewControllers

        XCTAssertEqual(value, .right)
    }

    func test_inheritedEnvironment_propagation() {

        /// This test sets up a nested element structure which contains nested Blueprint views;
        /// which have their own element hierarchies that they manage. By setting up this
        /// configuration, we check to see if `Environment` propagation works properly
        /// through multiple layers of nested blueprint views and environment customization.
        ///
        /// The final view and element structure we will have is:
        ///
        /// ```
        /// BlueprintView()
        ///     AdaptedEnvironment("root element")
        ///         TestElement(view: nil)
        ///             TestElement(view: view1)
        ///                 ViewWrappingBlueprintView()
        ///                     ---- End of Managed Blueprint Views ----
        ///
        ///                      BlueprintView()
        ///                          EnvironmentReader()
        ///                             AdaptedEnvironment("inner blueprint view")
        ///                                 TestElement(view: view2)
        ///                                     ViewWrappingBlueprintView()
        ///                                         ---- End of Managed Blueprint Views ----
        ///
        ///                                         BlueprintView()
        ///                                             EnvironmentReader()
        ///                                                 Empty()
        /// ```

        let view = BlueprintView()

        var readEnvironment1: Environment = .empty
        var readEnvironment2: Environment = .empty

        let view1 = ViewWrappingBlueprintView(frame: .zero)
        let view2 = ViewWrappingBlueprintView(frame: .zero)

        view1.blueprintView.element = EnvironmentReader { env in
            readEnvironment1 = env

            return TestElement(
                view: { view2 },
                child: nil
            )
            .adaptedEnvironment(key: InnerBlueprintViewKey.self, value: "inner blueprint view")
        }

        view2.blueprintView.element = EnvironmentReader { env in
            readEnvironment2 = env

            return Empty()
        }

        view.environment[ViewKey.self] = "view level environment"

        view.element = TestElement(
            view: nil,
            child: TestElement(
                view: { view1 },
                child: nil
            )
        )
        .adaptedEnvironment(key: RootElementKey.self, value: "root element")

        /// Force a layout of the element in the outer view.
        view.layoutIfNeeded()

        /// Now we can verify that the environment was propagated correctly.
        /// We will check both the `inheritedEnvironment` and an environment read
        /// off of an `EnvironmentReader` to ensure end to end consistency.

        XCTAssertEqual(view1.inheritedBlueprintEnvironment?[ViewKey.self], "view level environment")
        XCTAssertEqual(view1.inheritedBlueprintEnvironment?[RootElementKey.self], "root element")
        XCTAssertEqual(view1.inheritedBlueprintEnvironment?[InnerBlueprintViewKey.self], nil)
        XCTAssertEqual(readEnvironment1[ViewKey.self], "view level environment")
        XCTAssertEqual(readEnvironment1[RootElementKey.self], "root element")
        XCTAssertEqual(readEnvironment1[InnerBlueprintViewKey.self], nil)

        XCTAssertEqual(view2.inheritedBlueprintEnvironment?[ViewKey.self], "view level environment")
        XCTAssertEqual(view2.inheritedBlueprintEnvironment?[RootElementKey.self], "root element")
        XCTAssertEqual(view2.inheritedBlueprintEnvironment?[InnerBlueprintViewKey.self], "inner blueprint view")
        XCTAssertEqual(readEnvironment2[ViewKey.self], "view level environment")
        XCTAssertEqual(readEnvironment2[RootElementKey.self], "root element")
        XCTAssertEqual(readEnvironment2[InnerBlueprintViewKey.self], "inner blueprint view")

        enum ViewKey: EnvironmentKey { static let defaultValue: String? = nil }
        enum RootElementKey: EnvironmentKey { static let defaultValue: String? = nil }
        enum InnerBlueprintViewKey: EnvironmentKey { static let defaultValue: String? = nil }

        final class ViewWrappingBlueprintView: UIView {
            let blueprintView = BlueprintView()

            override init(frame: CGRect) {
                super.init(frame: frame)
                addSubview(blueprintView)
            }

            required init?(coder: NSCoder) { fatalError() }
        }

        struct TestElement<View: UIView>: Element {

            var view: (() -> View)?
            var child: Element?

            var content: ElementContent {
                if let child = self.child {
                    return .init(child: child)
                } else {
                    return .init(intrinsicSize: .zero)
                }
            }

            func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
                guard let view = self.view else {
                    return nil
                }

                return ViewDescription(View.self) { config in
                    config.builder = view
                }
            }
        }
    }

    func test_lifecycleEvents() {
        var events: [LifecycleTestEvent] = []
        var expectedEvents: [LifecycleTestEvent] = []

        let element = LifecycleTestElement(
            onAppear: {
                events.append(.appear(1))
            },
            onDisappear: {
                events.append(.disappear(1))
            },
            wrapped: LifecycleTestElement(
                onAppear: {
                    events.append(.appear(2))
                },
                onDisappear: {
                    events.append(.disappear(2))
                },
                wrapped: nil
            )
        )

        let view = BlueprintView()

        XCTAssertEqual(events, expectedEvents)

        // Add element before visible

        view.element = element
        view.ensureLayoutPass()

        XCTAssertEqual(events, expectedEvents)

        // Become visible

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.addSubview(view)

        expectedEvents.append(.appear(1))
        expectedEvents.append(.appear(2))
        XCTAssertEqual(events, expectedEvents)

        // Remove element while visible

        view.element = nil
        view.ensureLayoutPass()

        expectedEvents.append(.disappear(1))
        expectedEvents.append(.disappear(2))
        XCTAssertEqual(events, expectedEvents)

        // Add element while visible

        view.element = element
        view.ensureLayoutPass()

        expectedEvents.append(.appear(1))
        expectedEvents.append(.appear(2))
        XCTAssertEqual(events, expectedEvents)

        // Become not visible while element is set

        view.removeFromSuperview()

        expectedEvents.append(.disappear(1))
        expectedEvents.append(.disappear(2))
        XCTAssertEqual(events, expectedEvents)

        // Remove element while not visible

        view.element = nil
        view.ensureLayoutPass()

        XCTAssertEqual(events, expectedEvents)
    }

    func test_onAppearAfterViewUpdates() {
        let childViewDescriptionApplied = expectation(description: "child view description applied")
        let parentAppeared = expectation(description: "parent appeared")

        let element = LifecycleTestElement(
            onAppear: {
                parentAppeared.fulfill()
            },
            onDisappear: {},
            wrapped: CallbackElement(onViewDescriptionApplied: {
                childViewDescriptionApplied.fulfill()
            })
        )

        let view = BlueprintView()
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.addSubview(view)

        view.element = element
        view.ensureLayoutPass()

        // Check that parent element lifecycle callbacks happen *after* view updates
        // of their children, so things like focus triggers can be set up.
        wait(for: [childViewDescriptionApplied, parentAppeared], timeout: 1, enforceOrder: true)
    }

    func test_intrinsicContentSize_noElement() {
        let view = BlueprintView()

        let noIntrinsicMetricSize = CGSize(
            width: UIView.noIntrinsicMetric,
            height: UIView.noIntrinsicMetric
        )

        XCTAssertEqual(view.intrinsicContentSize, noIntrinsicMetricSize)
    }

    func test_intrinsicContentSize_constrained() {
        let view = BlueprintView()

        let size = CGSize(
            width: 42,
            height: 7
        )

        view.element = Empty().constrainedTo(size: size)

        XCTAssertEqual(view.intrinsicContentSize, size)
    }

    func test_intrinsicContentSize_changesInvalidatesCachedSize() {
        let view = BlueprintView()

        var measureCount = 0

        func makeElement(size: CGSize) -> Element {
            MeasurableElement { constraint in
                measureCount += 1
                return size
            }
        }

        view.element = makeElement(size: CGSize(
            width: 13,
            height: 99
        ))

        // Query intrinsicContentSize so that it is cached.
        _ = view.intrinsicContentSize
        XCTAssertEqual(measureCount, 1)

        _ = view.intrinsicContentSize
        // Re-querying intrinsicContentSize without changes should skip measurement.
        XCTAssertEqual(measureCount, 1)

        let size = CGSize(
            width: 42,
            height: 7
        )

        view.element = makeElement(size: size)

        XCTAssertEqual(view.intrinsicContentSize, size)
        XCTAssertEqual(measureCount, 2)
    }
}

fileprivate struct MeasurableElement: Element {

    var validate: (SizeConstraint) -> CGSize

    var content: ElementContent {
        ElementContent { constraint -> CGSize in
            self.validate(constraint)
        }
    }

    func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        nil
    }
}

fileprivate struct SimpleViewElement: Element {

    var color: UIColor

    var content: ElementContent {
        ElementContent(intrinsicSize: CGSize(width: 100, height: 100))
    }

    func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        UIView.describe { config in
            config[\.backgroundColor] = color
        }
    }

}

private struct TestElement1: Element {
    var tag: Int

    var content: ElementContent {
        ElementContent(intrinsicSize: .zero)
    }

    func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        UIView.describe { config in
            config[\.tag] = tag
        }
    }
}

private struct TestElement2: Element {
    var tag: Int

    var content: ElementContent {
        ElementContent(intrinsicSize: .zero)
    }

    func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        UIView.describe { config in
            config[\.tag] = tag
        }
    }
}

private struct TestContainer: Element {
    var children: [Element]

    var content: ElementContent {
        ElementContent(layout: TestLayout()) { builder in
            for child in children {
                builder.add(element: child)
            }
        }
    }

    func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        nil
    }

    private class TestLayout: Layout {
        func measure(in constraint: SizeConstraint, items: [(traits: (), content: Measurable)]) -> CGSize {
            .zero
        }

        func layout(size: CGSize, items: [(traits: (), content: Measurable)]) -> [LayoutAttributes] {
            Array(repeating: LayoutAttributes(size: .zero), count: items.count)
        }
    }
}

private struct CallbackElement: Element {
    var onViewDescriptionApplied: () -> Void

    var content: ElementContent {
        ElementContent(intrinsicSize: .zero)
    }

    func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        UIView.describe { config in
            config.apply { _ in
                onViewDescriptionApplied()
            }
        }
    }
}

private struct LifecycleTestElement: Element {
    var onAppear: LifecycleCallback
    var onDisappear: LifecycleCallback

    var wrapped: Element?

    var content: ElementContent {
        if let wrapped = wrapped {
            return ElementContent(child: wrapped)
        } else {
            return ElementContent(intrinsicSize: .zero)
        }
    }

    func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        UIView.describe { config in
            config.onAppear = onAppear
            config.onDisappear = onDisappear
        }
    }
}

private enum LifecycleTestEvent: Equatable, CustomStringConvertible {
    case appear(Int)
    case disappear(Int)

    var description: String {
        switch self {
        case .appear(let i):
            return "appear(\(i))"
        case .disappear(let i):
            return "disappear(\(i))"
        }
    }
}

