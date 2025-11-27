import UIKit
import XCTest
@testable import BlueprintUI


class UIViewElementTests: XCTestCase {

    func test_measuring() {
        // Due to the static caching of UIViewElementMeasurer, this struct is nested to give it a
        // unique object identifier. It only makes sense to test a unique UIViewElement type.
        struct TestElement: UIViewElement {

            var size: CGSize

            typealias UIViewType = TestView

            static var makeUIView_count: Int = 0

            func makeUIView() -> TestView {
                Self.makeUIView_count += 1

                return TestView()
            }

            static var updateUIView_count: Int = 0
            static var updateUIView_isMeasuring_count: Int = 0

            func updateUIView(_ view: TestView, with context: UIViewElementContext) {
                Self.updateUIView_count += 1

                if context.isMeasuring {
                    Self.updateUIView_isMeasuring_count += 1
                }

                view.sizeThatFits = size
            }
        }

        XCTAssertEqual(
            TestElement(size: CGSize(width: 20.0, height: 30.0)).content.measure(in: .unconstrained),
            CGSize(width: 20.0, height: 30.0)
        )

        // Should have allocated one view for measurement.
        XCTAssertEqual(TestElement.makeUIView_count, 1)
        // Should have updated the view once.
        XCTAssertEqual(TestElement.updateUIView_count, 1)

        XCTAssertEqual(
            TestElement(size: CGSize(width: 40.0, height: 60.0)).content.measure(in: .unconstrained),
            CGSize(width: 40.0, height: 60.0)
        )

        // Should reuse the same view for measurement.
        XCTAssertEqual(TestElement.makeUIView_count, 1)
        // Should have updated the view again.
        XCTAssertEqual(TestElement.updateUIView_count, 2)
    }

    func test_blueprintview() {
        // Due to the static caching of UIViewElementMeasurer, this struct is nested to give it a
        // unique object identifier. It only makes sense to test a unique UIViewElement type.
        struct TestElement: UIViewElement {

            var size: CGSize

            typealias UIViewType = TestView

            static var makeUIView_count: Int = 0

            func makeUIView() -> TestView {
                Self.makeUIView_count += 1

                return TestView()
            }

            static var updateUIView_count: Int = 0
            static var updateUIView_isMeasuring_count: Int = 0

            func updateUIView(_ view: TestView, with context: UIViewElementContext) {
                Self.updateUIView_count += 1

                if context.isMeasuring {
                    Self.updateUIView_isMeasuring_count += 1
                }

                view.sizeThatFits = size
            }
        }

        let blueprintView = BlueprintView()

        // Wrap the element so it needs to be measured.
        blueprintView.element = TestElement(size: CGSize(width: 20.0, height: 30.0))
            .centered()


        // trigger a layout pass
        _ = blueprintView.currentNativeViewControllers

        // Should have allocated one view for measurement and one view for display.
        XCTAssertEqual(TestElement.makeUIView_count, 2)
        // Should have updated the view once for measurement and once for display.
        XCTAssertEqual(TestElement.updateUIView_count, 2)
        // Should have updated the view once for measurement.
        XCTAssertEqual(TestElement.updateUIView_isMeasuring_count, 1)
    }

    func test_environment() {
        enum TestKey: EnvironmentKey {
            static let defaultValue: Void? = nil
            static func isCacheablyEquivalent(lhs: Void?, rhs: Void?, in context: CrossLayoutCacheableContext) -> Bool {
                lhs == nil && rhs == nil || rhs != nil && lhs != nil
            }
        }

        @propertyWrapper
        final class Box<Value> {
            var wrappedValue: Value

            init(wrappedValue: Value) {
                self.wrappedValue = wrappedValue
            }
        }

        struct TestElement: UIViewElement {
            @Box var environment: Environment?

            var validateEnvironment: (BlueprintView) -> Void = { _ in }

            func makeUIView() -> TestView {
                let view = TestView()
                view.validateEnvironment = validateEnvironment
                return view
            }

            func updateUIView(_ view: TestView, with context: UIViewElementContext) {
                view.validateEnvironment = validateEnvironment
                environment = context.environment
            }
        }

        var env = Environment.empty
        env[TestKey.self] = ()

        do {
            // Environment is passed during measurement.
            let element = TestElement()

            _ = element.content.measure(
                in: .unconstrained,
                environment: env
            )
            XCTAssertNotNil(element.environment?[TestKey.self])
        }

        do {
            // Enviroment is passed during apply.
            let element = TestElement()

            let description = element.backingViewDescription(
                with: .init(
                    bounds: .zero,
                    subtreeExtent: nil,
                    environment: env
                )
            )
            description?.apply(to: element.makeUIView())
            XCTAssertNotNil(element.environment?[TestKey.self])
        }

        do {
            let blueprintView = BlueprintView(frame: .init(origin: .zero, size: .init(width: 100, height: 100)))

            var element = TestElement()

            element.validateEnvironment = { view in
                XCTAssertNotNil(view.inheritedBlueprintEnvironment)
            }

            /// `.centered()` so we're not the root element, so we are measured as well.
            blueprintView.element = element.centered()

            blueprintView.layoutIfNeeded()
        }
    }

    func test_removeAllObjects() {

        struct TestElement: UIViewElement {
            func makeUIView() -> UIView {
                UIView()
            }

            func updateUIView(_ view: UIView, with context: BlueprintUI.UIViewElementContext) {}
        }

        let measurer = UIViewElementMeasurer()

        _ = measurer.measure(element: TestElement(), constraint: .unconstrained, environment: .empty)

        XCTAssertEqual(measurer.cachedViewCount, 1)

        measurer.removeAllObjects()

        XCTAssertEqual(measurer.cachedViewCount, 0)
    }
}

fileprivate final class TestView: UIView {

    var sizeThatFits: CGSize = .zero

    let blueprintView: BlueprintView

    var validateEnvironment: (BlueprintView) -> Void = { _ in }

    override init(frame: CGRect) {
        blueprintView = BlueprintView()

        super.init(frame: frame)

        addSubview(blueprintView)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        validateEnvironment(blueprintView)

        return sizeThatFits
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        blueprintView.frame = bounds

        validateEnvironment(blueprintView)
    }
}
