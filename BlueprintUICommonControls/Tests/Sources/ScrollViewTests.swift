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
            identifier: "fittingContent",
            layoutModes: [.caffeinated]
        )

        compareSnapshot(
            of: InfiniteBox()
                .scrollable(.fittingWidth)
                .inset(uniform: 10),
            size: CGSize(width: 100, height: 100),
            identifier: "fittingWidth",
            layoutModes: [.caffeinated]
        )

        compareSnapshot(
            of: InfiniteBox()
                .scrollable(.fittingHeight)
                .inset(uniform: 10),
            size: CGSize(width: 100, height: 100),
            identifier: "fittingHeight",
            layoutModes: [.caffeinated]
        )
    }

    func test_calculateContentInset() {
        // No inset

        XCTAssertEqual(
            UIEdgeInsets.zero,

            ScrollView.calculateContentInset(
                scrollViewInsets: .zero,
                safeAreaInsets: UIEdgeInsets(top: 10.0, left: 11.0, bottom: 12.0, right: 13.0),
                keyboardBottomInset: .zero,
                refreshControlState: .disabled,
                refreshControlBounds: CGRect(origin: .zero, size: CGSize(width: 25.0, height: 25.0))
            )
        )

        // Keyboard Inset

        XCTAssertEqual(
            UIEdgeInsets(top: 10.0, left: 11.0, bottom: 50.0, right: 13.0),

            ScrollView.calculateContentInset(
                scrollViewInsets: UIEdgeInsets(top: 10.0, left: 11.0, bottom: 12.0, right: 13.0),
                safeAreaInsets: UIEdgeInsets(top: 10.0, left: 11.0, bottom: 12.0, right: 13.0),
                keyboardBottomInset: 50.0,
                refreshControlState: .disabled,
                refreshControlBounds: CGRect(origin: .zero, size: CGSize(width: 25.0, height: 25.0))
            )
        )

        // Keyboard Inset and refreshing state
        let expectedTopInset = 10.0

        XCTAssertEqual(
            UIEdgeInsets(top: expectedTopInset, left: 11.0, bottom: 50.0, right: 13.0),

            ScrollView.calculateContentInset(
                scrollViewInsets: UIEdgeInsets(top: 10.0, left: 11.0, bottom: 12.0, right: 13.0),
                safeAreaInsets: UIEdgeInsets(top: 10.0, left: 11.0, bottom: 12.0, right: 13.0),
                keyboardBottomInset: 50.0,
                refreshControlState: .refreshing,
                refreshControlBounds: CGRect(origin: .zero, size: CGSize(width: 25.0, height: 25.0))
            )
        )
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
}
