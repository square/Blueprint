//
//  UIViewElementTests.swift
//  BlueprintUI-Unit-Tests
//
//  Created by Kyle Van Essen on 6/8/20.
//

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
            static var defaultValue: Void { () }

            static func isEquivalent(_ lhs: (), _ rhs: ()) -> Bool {
                true
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

            func makeUIView() -> TestView {
                TestView()
            }

            func updateUIView(_ view: TestView, with context: UIViewElementContext) {
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
    }
}

fileprivate final class TestView: UIView {

    var sizeThatFits: CGSize = .zero

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        sizeThatFits
    }
}
