import Foundation
import XCTest

import BlueprintUI

@testable import BlueprintUICommonControls


class ScrollViewTests: XCTestCase {

    // When a scrollview places a subelement that has an infinite size, it defaults to replacing
    // those dimensions with the size of the scrollview itself.
    func test_infiniteContent() throws {

        struct InfiniteBox: Element {
            var content: ElementContent {
                ElementContent(intrinsicSize: .infinity)
            }

            func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
                UIView.describe { view in
                    view[\.backgroundColor] = .red
                }
            }
        }

        compareSnapshot(
            of: InfiniteBox()
                .scrollable(.fittingContent)
                .inset(uniform: 10),
            size: CGSize(width: 100, height: 100),
            identifier: "fittingContent"
        )

        compareSnapshot(
            of: InfiniteBox()
                .scrollable(.fittingWidth)
                .inset(uniform: 10),
            size: CGSize(width: 100, height: 100),
            identifier: "fittingWidth"
        )

        compareSnapshot(
            of: InfiniteBox()
                .scrollable(.fittingHeight)
                .inset(uniform: 10),
            size: CGSize(width: 100, height: 100),
            identifier: "fittingHeight"
        )
    }

    func test_calculateContentInset() {
        // Test case 1: No inset.
        XCTAssertEqual(
            UIEdgeInsets.zero,

            ScrollView.calculateContentInset(
                scrollViewInsets: .zero,
                safeAreaInsets: UIEdgeInsets(top: 10.0, left: 11.0, bottom: 12.0, right: 13.0),
                keyboardBottomInset: .zero,
                bottomEdgeConfiguration: .none
            ).contentInset
        )

        // Test case 2: Keyboard Inset.
        XCTAssertEqual(
            UIEdgeInsets(top: 10.0, left: 11.0, bottom: 50.0, right: 13.0),

            ScrollView.calculateContentInset(
                scrollViewInsets: UIEdgeInsets(top: 10.0, left: 11.0, bottom: 12.0, right: 13.0),
                safeAreaInsets: UIEdgeInsets(top: 10.0, left: 11.0, bottom: 12.0, right: 13.0),
                keyboardBottomInset: 50.0,
                bottomEdgeConfiguration: .none
            ).contentInset
        )

        // Test case 3: Anomalous Keyboard Inset.
        XCTAssertEqual(
            UIEdgeInsets(top: 10.0, left: 11.0, bottom: 12.0, right: 13.0),

            ScrollView.calculateContentInset(
                scrollViewInsets: UIEdgeInsets(top: 10.0, left: 11.0, bottom: 12.0, right: 13.0),
                safeAreaInsets: UIEdgeInsets(top: 10.0, left: 11.0, bottom: 12.0, right: 13.0),
                // Since this value is < 1, the resulting bottom inset should be unchanged.
                keyboardBottomInset: 0.15,
                bottomEdgeConfiguration: .none
            ).contentInset
        )

        // Test case 4: Full result with .none bottom edge configuration.
        let noneResult = ScrollView.calculateContentInset(
            scrollViewInsets: UIEdgeInsets(top: 10.0, left: 11.0, bottom: 12.0, right: 13.0),
            safeAreaInsets: UIEdgeInsets(top: 10.0, left: 11.0, bottom: 12.0, right: 13.0),
            keyboardBottomInset: 50,
            bottomEdgeConfiguration: .none
        )
        XCTAssertEqual(
            noneResult.contentInset,
            UIEdgeInsets(top: 10.0, left: 11.0, bottom: 50.0, right: 13.0) // 12 + 50 - 12 (safe area)
        )
        XCTAssertEqual(noneResult.indicatorBottomInset, 50.0)

        // Test case 5: Full result with .underflowsSafeArea bottom edge configuration.
        let underflowResult = ScrollView.calculateContentInset(
            scrollViewInsets: UIEdgeInsets(top: 10.0, left: 11.0, bottom: 12.0, right: 13.0),
            safeAreaInsets: UIEdgeInsets(top: 10.0, left: 11.0, bottom: 12.0, right: 13.0),
            keyboardBottomInset: 50,
            bottomEdgeConfiguration: .underflowsSafeArea
        )
        XCTAssertEqual(
            underflowResult.contentInset,
            UIEdgeInsets(top: 10.0, left: 11.0, bottom: 62.0, right: 13.0) // 12 + 50 (no safe area subtraction)
        )
        XCTAssertEqual(underflowResult.indicatorBottomInset, 50.0) // 62 - 12 (safe area)

        // Test case 6: Full result with .overflowsSafeArea bottom edge configuration.
        let overflowSafeAreaResult = ScrollView.calculateContentInset(
            scrollViewInsets: UIEdgeInsets(top: 10.0, left: 11.0, bottom: 24.0, right: 13.0),
            safeAreaInsets: UIEdgeInsets(top: 10.0, left: 11.0, bottom: 12.0, right: 13.0),
            keyboardBottomInset: 50,
            bottomEdgeConfiguration: .overflowsSafeArea
        )
        XCTAssertEqual(
            overflowSafeAreaResult.contentInset,
            UIEdgeInsets(top: 10.0, left: 11.0, bottom: 62.0, right: 13.0) // 24 + 50 - 12 (safe area)
        )
        XCTAssertEqual(overflowSafeAreaResult.indicatorBottomInset, 50.0) // 62 - 12 (safe area)

        // Test case 7: Full result with .overflowsBounds bottom edge configuration.
        let overflowBoundsResult = ScrollView.calculateContentInset(
            scrollViewInsets: UIEdgeInsets(top: 10.0, left: 11.0, bottom: 12.0, right: 13.0),
            safeAreaInsets: UIEdgeInsets(top: 10.0, left: 11.0, bottom: 12.0, right: 13.0),
            keyboardBottomInset: 50,
            bottomEdgeConfiguration: .overflowsBounds
        )
        XCTAssertEqual(
            overflowBoundsResult.contentInset,
            UIEdgeInsets(top: 10.0, left: 11.0, bottom: 50.0, right: 13.0) // 12 + 50 - 12 (safe area)
        )
        XCTAssertEqual(overflowBoundsResult.indicatorBottomInset, 50.0)
    }

    func test_contentSizes() {
        let boundingSize = CGSize(width: 100, height: 100)

        func test(
            contentSize: ScrollView.ContentSize,
            file: StaticString = #file,
            testName: String = #function,
            line: UInt = #line
        ) {
            let identifier: String
            switch contentSize {
            case .custom:
                identifier = "custom"
            default:
                identifier = "\(contentSize)"
            }

            do {
                var scrollView = ScrollView(wrapping: OverflowElement())

                scrollView.contentSize = contentSize

                let measuredSize = scrollView.content.measure(in: SizeConstraint(boundingSize))

                compareSnapshot(
                    of: scrollView,
                    size: measuredSize,
                    identifier: "overflow_\(identifier)",
                    file: file,
                    testName: testName,
                    line: line
                )
            }

            do {
                var scrollView = ScrollView(wrapping: UnderflowElement())

                scrollView.contentSize = contentSize

                compareSnapshot(
                    of: scrollView,
                    size: boundingSize,
                    identifier: "underflow_\(identifier)",
                    file: file,
                    testName: testName,
                    line: line
                )
            }
        }

        test(contentSize: .custom(CGSize(width: 80, height: 80)))
        test(contentSize: .fittingContent)
        test(contentSize: .fittingHeight)
        test(contentSize: .fittingWidth)
    }

    private struct UnderflowElement: ProxyElement {
        var elementRepresentation: Element {
            Row { row in
                row.verticalAlignment = .fill
                row.add(
                    growPriority: 0,
                    child: Column { column in
                        column.add(
                            growPriority: 0,
                            child: Label(text: "a")
                        )
                        column.add(
                            growPriority: 1,
                            child: Spacer(size: .zero)
                        )
                        column.add(
                            growPriority: 0,
                            child: Label(text: "c")
                        )
                    }
                )
                row.add(
                    growPriority: 1,
                    child: Spacer(size: .zero)
                )
                row.add(
                    growPriority: 0,
                    child: Column { column in
                        column.add(
                            growPriority: 0,
                            child: Label(text: "b")
                        )
                        column.add(
                            growPriority: 1,
                            child: Spacer(size: .zero)
                        )
                        column.add(
                            growPriority: 0,
                            child: Label(text: "d")
                        )
                    }
                )
            }
        }
    }

    private struct OverflowElement: ProxyElement {
        private let lipsum = """
        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut pretium ante sapien, ac placerat mi scelerisque at.
        """

        var elementRepresentation: Element {
            Label(text: lipsum)
        }
    }

    // MARK: - Edge Calculation Tests

    func test_calculateInset_minEdge() {

        // Test case 1: Content overflows bounds (contentMinEdge < boundsMinEdge).
        let overflowsBounds = ScrollView.calculateEdgeConfiguration(
            contentMinEdge: 5.0,
            safeAreaMinEdge: 20.0,
            boundsMinEdge: 10.0
        )
        XCTAssertEqual(overflowsBounds, .overflowsBounds)

        // Test case 2: Content within bounds but overflows safe area.
        let overflowsSafeArea = ScrollView.calculateEdgeConfiguration(
            contentMinEdge: 15.0,
            safeAreaMinEdge: 20.0,
            boundsMinEdge: 10.0
        )
        XCTAssertEqual(overflowsSafeArea, .overflowsSafeArea)

        // Test case 3: Content within safe area.
        let underflowsSafeArea = ScrollView.calculateEdgeConfiguration(
            contentMinEdge: 25.0,
            safeAreaMinEdge: 20.0,
            boundsMinEdge: 10.0
        )
        XCTAssertEqual(underflowsSafeArea, .underflowsSafeArea)

        // Test case 4: Edge case - content exactly at safe area edge.
        let exactlySafeArea = ScrollView.calculateEdgeConfiguration(
            contentMinEdge: 20.0,
            safeAreaMinEdge: 20.0,
            boundsMinEdge: 10.0
        )
        XCTAssertEqual(exactlySafeArea, .underflowsSafeArea)

        // Test case 5: Edge case - content exactly at bounds edge.
        let exactlyBounds = ScrollView.calculateEdgeConfiguration(
            contentMinEdge: 10.0,
            safeAreaMinEdge: 20.0,
            boundsMinEdge: 10.0
        )
        XCTAssertEqual(exactlyBounds, .overflowsSafeArea)
    }

    func test_calculateInset_maxEdge() {

        // Test case 1: Content overflows bounds (contentMaxEdge > boundsMaxEdge).
        let overflowsBounds = ScrollView.calculateEdgeConfiguration(
            contentMaxEdge: 110.0,
            adjustedMaxEdge: 110.0,
            safeAreaMaxEdge: 80.0,
            boundsMaxEdge: 100.0
        )
        XCTAssertEqual(overflowsBounds, .overflowsBounds)

        // Test case 2: Content within bounds but adjusted content overflows safe area.
        let overflowsSafeArea = ScrollView.calculateEdgeConfiguration(
            contentMaxEdge: 90.0,
            adjustedMaxEdge: 95.0, // After adjustment from top/left insets
            safeAreaMaxEdge: 80.0,
            boundsMaxEdge: 100.0
        )
        XCTAssertEqual(overflowsSafeArea, .overflowsSafeArea)

        // Test case 3: Content and adjusted content within safe area.
        let underflowsSafeArea = ScrollView.calculateEdgeConfiguration(
            contentMaxEdge: 70.0,
            adjustedMaxEdge: 75.0,
            safeAreaMaxEdge: 80.0,
            boundsMaxEdge: 100.0
        )
        XCTAssertEqual(underflowsSafeArea, .underflowsSafeArea)

        // Test case 4: Edge case - adjusted content exactly at safe area edge.
        let exactlySafeArea = ScrollView.calculateEdgeConfiguration(
            contentMaxEdge: 75.0,
            adjustedMaxEdge: 80.0,
            safeAreaMaxEdge: 80.0,
            boundsMaxEdge: 100.0
        )
        XCTAssertEqual(exactlySafeArea, .underflowsSafeArea)

        // Test case 5: Edge case - content exactly at bounds edge.
        let exactlyBounds = ScrollView.calculateEdgeConfiguration(
            contentMaxEdge: 100.0,
            adjustedMaxEdge: 100.0,
            safeAreaMaxEdge: 80.0,
            boundsMaxEdge: 100.0
        )
        XCTAssertEqual(exactlyBounds, .overflowsSafeArea)
    }
}
