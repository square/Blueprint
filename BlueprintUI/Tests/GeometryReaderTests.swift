import XCTest
@testable import BlueprintUI

final class GeometryReaderTests: XCTestCase {

    func test_measuring() {
        let constrainedSize = CGSize(width: 100, height: 100)
        let unconstrainedSize = CGSize(width: 200, height: 200)

        let element = GeometryReader { geometry -> Element in
            if geometry.constraint.width.isConstrained {
                return Spacer(size: constrainedSize)
            } else {
                return Spacer(size: unconstrainedSize)
            }
        }

        XCTAssertEqual(
            element.content.measure(in: .unconstrained),
            unconstrainedSize
        )

        XCTAssertEqual(
            element.content.measure(in: SizeConstraint(.zero)),
            constrainedSize
        )
    }

    func test_layout() {
        let element = GeometryReader { geometry -> Element in
            // Create an element with half the dimensions of the available size,
            // aligned in the bottom right.

            let width = geometry.constraint.maximum.width / 2.0
            let height = geometry.constraint.maximum.height / 2.0

            return Spacer(width: width, height: height)
                .aligned(vertically: .bottom, horizontally: .trailing)
        }

        /// Walk a node tree down each node's first child and return the frame of the first leaf node.
        func leafChildFrame(in node: LayoutResultNode) -> CGRect {
            if let childNode = node.children.first?.node {
                return leafChildFrame(in: childNode)
            }
            return node.layoutAttributes.frame
        }

        let layoutResultNode = element.layout(frame: CGRect(x: 0, y: 0, width: 100, height: 100))

        let frame = leafChildFrame(in: layoutResultNode)
        XCTAssertEqual(frame, CGRect(x: 50, y: 50, width: 50, height: 50))
    }

    func test_nestedMeasuring() {

        enum TestKey: EnvironmentKey {
            static let defaultValue: CGFloat = 10
        }

        let layoutExpectation = expectation(description: "layout performed")

        let element = GeometryReader { geometry in

            let adaptiveElement = EnvironmentReader { environment in
                Spacer(environment[TestKey.self])
            }

            XCTAssertEqual(
                geometry.measure(element: adaptiveElement),
                CGSize(width: 10, height: 10)
            )

            XCTAssertEqual(
                geometry.measure(
                    element: adaptiveElement.adaptedEnvironment(key: TestKey.self, value: 5)
                ),
                CGSize(width: 5, height: 5)
            )

            layoutExpectation.fulfill()

            return Empty()
        }

        _ = element.layout(frame: CGRect(x: 0, y: 0, width: 20, height: 20))

        wait(for: [layoutExpectation], timeout: 5)
    }

    func test_dynamicSubelements() {
        let threshold: CGFloat = 100
        let size = CGSize(width: 120, height: 120)

        let element: Element = Row { outerRow in
            outerRow.horizontalUnderflow = .growUniformly
            outerRow.horizontalOverflow = .condenseUniformly
            outerRow.verticalAlignment = .fill

            outerRow.addFlexible(
                child: GeometryReader { geometry in

                    return Row { innerRow in
                        innerRow.horizontalUnderflow = .growUniformly
                        innerRow.horizontalOverflow = .condenseUniformly
                        innerRow.verticalAlignment = .fill

                        if let width = geometry.constraint.width.constrainedValue, width < threshold {
                            // If constrained < 100, 2 children
                            innerRow.addFixed(child: Spacer(1))
                            innerRow.addFixed(child: Spacer(1))
                        } else {
                            // else 1 child
                            innerRow.addFixed(child: Spacer(threshold))
                        }
                    }
                }
            )

            outerRow.addFlexible(child: Spacer(threshold / 2))
        }

        // during layout:
        // 1. Outer row measures GR with full width
        // 2. GR body evaluates as a row with 1 child
        // 3. Outer row measures again with reduced width
        // 4. GR body evaluates as a row with 2 children
        // 5. Subelement count has changed, as well as content of child 1

        LayoutMode.caffeinated(options: .notAssumingSubelementsStable).performAsDefault {
            let frames = element
                .layout(frame: CGRect(origin: .zero, size: size))
                .queryLayout(for: Spacer.self)
                .map { $0.layoutAttributes.frame }

            XCTAssertEqual(
                frames,
                [
                    CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 1, height: 120)),
                    CGRect(origin: CGPoint(x: 1, y: 0), size: CGSize(width: 1, height: 120)),
                    CGRect(origin: CGPoint(x: 85, y: 0), size: CGSize(width: 35, height: 120)),
                ]
            )
        }
    }
}

extension LayoutOptions {
    static let notAssumingSubelementsStable = LayoutOptions(
        hintRangeBoundaries: true,
        searchUnconstrainedKeys: true,
        assumeStableSubelements: false
    )
}

extension SizeConstraint.Axis {
    fileprivate var isConstrained: Bool {
        switch self {
        case .atMost:
            return true
        case .unconstrained:
            return false
        }
    }
}
