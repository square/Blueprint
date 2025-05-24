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
                    config[\.onLayoutSubviews] = onLayoutSubviews
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
                if let child = child {
                    return .init(child: child)
                } else {
                    return .init(intrinsicSize: .zero)
                }
            }

            func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
                guard let view = view else {
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

    func test_intrinsicContentSize_element() {
        let view = BlueprintView()

        let space: CGFloat = 100.0 * 100

        func setElement() {
            view.element = MeasurableElement { constraint in

                let width = constraint.width.constrainedValue ?? 100.0

                return CGSize(
                    width: width,
                    height: space / width
                )
            }
        }

        setElement()

        // Test the behavior of no width – should be an unconstrained measurement.

        view.frame.size.width = 0

        XCTAssertEqual(
            view.intrinsicContentSize,
            CGSize(width: 100, height: 100)
        )

        // Constrained width should use that to measure.

        view.frame.size.width = 50

        XCTAssertEqual(
            view.intrinsicContentSize,
            CGSize(width: 50, height: 200)
        )

        // Setting the element should not change the result.

        setElement()

        XCTAssertEqual(
            view.intrinsicContentSize,
            CGSize(width: 50, height: 200)
        )
    }

    func test_measurement_caching() {
        let view = BlueprintView()

        var measureCount = 0

        func makeElement(size: CGSize) -> Element {
            MeasurableElement { constraint in
                measureCount += 1
                return size
            }
        }

        view.element = makeElement(size: .init(
            width: 13,
            height: 99
        ))

        // Ensure that the measurement is cached

        _ = view.intrinsicContentSize
        XCTAssertEqual(measureCount, 1)
        _ = view.sizeThatFits(.init(width: 50, height: 100))
        XCTAssertEqual(measureCount, 2)

        // Measuring again should be cached.

        _ = view.intrinsicContentSize
        _ = view.sizeThatFits(.init(width: 50, height: 100))
        XCTAssertEqual(measureCount, 2)

        // Measuring in a different size should be cached.

        _ = view.sizeThatFits(.init(width: 100, height: 200))
        XCTAssertEqual(measureCount, 3)

        // View size hasn't changed, so this should not re-measure.

        _ = view.intrinsicContentSize
        XCTAssertEqual(measureCount, 3)

        // Changing the element should re-measure

        let size2 = CGSize(
            width: 42,
            height: 7
        )

        view.element = makeElement(size: size2)

        XCTAssertEqual(view.intrinsicContentSize, size2)
        XCTAssertEqual(measureCount, 4)

        XCTAssertEqual(view.sizeThatFits(.init(width: 100, height: 200)), size2)
        XCTAssertEqual(measureCount, 5)

        // If the environment goes from empty to empty, no measurement should occur.

        view.environment = .empty

        XCTAssertEqual(view.intrinsicContentSize, size2)
        XCTAssertEqual(measureCount, 5)

        XCTAssertEqual(view.sizeThatFits(.init(width: 100, height: 200)), size2)
        XCTAssertEqual(measureCount, 5)

        // Changing the environment should re-measure (any change should do,
        // the environment has no concept of equality presently).

        var newEnv = Environment.empty
        newEnv.safeAreaInsets = UIEdgeInsets(top: 1, left: 2, bottom: 3, right: 4)
        view.environment = newEnv

        XCTAssertEqual(view.intrinsicContentSize, size2)
        XCTAssertEqual(measureCount, 6)

        XCTAssertEqual(view.sizeThatFits(.init(width: 100, height: 200)), size2)
        XCTAssertEqual(measureCount, 7)

        // Changing the environment inheritance since we cannot currently equate environments.

        view.automaticallyInheritsEnvironmentFromContainingBlueprintViews.toggle()

        XCTAssertEqual(view.intrinsicContentSize, size2)
        XCTAssertEqual(measureCount, 8)

        XCTAssertEqual(view.sizeThatFits(.init(width: 100, height: 200)), size2)
        XCTAssertEqual(measureCount, 9)

        // ...Finally ensure that no further changes do not re-measure.

        XCTAssertEqual(view.intrinsicContentSize, size2)
        XCTAssertEqual(measureCount, 9)

        XCTAssertEqual(view.sizeThatFits(.init(width: 100, height: 200)), size2)
        XCTAssertEqual(measureCount, 9)
    }

    func test_sizeThatFits_cache() {
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

        // Query sizeThatFits so that it is cached.
        _ = view.sizeThatFits(CGSize(width: 100, height: 200))
        XCTAssertEqual(measureCount, 1)

        _ = view.sizeThatFits(CGSize(width: 100, height: 200))
        // Re-querying sizeThatFits without changing the size should skip measurement.
        XCTAssertEqual(measureCount, 1)

        _ = view.sizeThatFits(CGSize(width: 150, height: 200))
        // sizeThatFits with a new size should re-measure.
        XCTAssertEqual(measureCount, 2)

        let size = CGSize(
            width: 42,
            height: 7
        )

        view.element = makeElement(size: size)
        // Changing the element should cause another measurement.
        XCTAssertEqual(view.sizeThatFits(CGSize(width: 150, height: 200)), size)
        XCTAssertEqual(measureCount, 3)
    }

    func test_lifecycleCallbacks_dont_cause_crash() {

        let expectation = expectation(description: "Re-rendered")

        withHostedView { view in

            var hasRerendered = false

            func render() {
                view.element = SimpleViewElement(color: .black).onAppear {

                    /// Simulate an onAppear event triggering a re-render.

                    if hasRerendered == false {
                        hasRerendered = true
                        render()

                        expectation.fulfill()
                    }
                }

                view.layoutIfNeeded()
            }

            render()
        }

        waitForExpectations(timeout: 1)
    }

    func test_metrics_delegate_completedRenderWith() {
        let testMetricsDelegate = TestMetricsDelegate()

        let view = BlueprintView()
        view.metricsDelegate = testMetricsDelegate

        view.setNeedsLayout()
        view.layoutIfNeeded()

        guard let metric = testMetricsDelegate.metrics.first else {
            XCTFail("No metric generated")
            return
        }

        XCTAssertTrue(metric.totalDuration > 0)
        XCTAssertTrue(metric.layoutDuration > 0)
        XCTAssertTrue(metric.viewUpdateDuration > 0)

        // Sanity check that total duration is the sum of the two components.
        // `accuracy` is generous to account for any accumated error during arithmetic.
        XCTAssertEqual(
            metric.totalDuration, metric.layoutDuration + metric.viewUpdateDuration,
            accuracy: metric.totalDuration.ulp * 2
        )
    }
}

fileprivate struct MeasurableElement: Element {

    var validate: (SizeConstraint) -> CGSize

    var content: ElementContent {
        ElementContent { constraint -> CGSize in
            validate(constraint)
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
        func sizeThatFits(
            proposal: SizeConstraint,
            subelements: Subelements,
            environment: Environment,
            cache: inout ()
        ) -> CGSize {
            .zero
        }

        func placeSubelements(
            in size: CGSize,
            subelements: Subelements,
            environment: Environment,
            cache: inout ()
        ) {
            for subelement in subelements {
                subelement.place(in: .zero)
            }
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

private class TestMetricsDelegate: BlueprintViewMetricsDelegate {

    var metrics: [BlueprintUI.BlueprintViewRenderMetrics] = []

    func blueprintView(
        _ view: BlueprintUI.BlueprintView,
        completedRenderWith metrics: BlueprintUI.BlueprintViewRenderMetrics
    ) {
        self.metrics.append(metrics)
    }
}
