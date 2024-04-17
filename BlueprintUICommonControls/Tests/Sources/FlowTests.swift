import BlueprintUICommonControls
import XCTest
@testable import BlueprintUI


/// Note; While `Flow` lives in `BlueprintUI`, we're putting some snapshot tests in
/// `BlueprintUICommonControls` for easier verification of the layout.

class FlowTests: XCTestCase {

    private static let elements = [
        ConstrainedSize(width: 50, height: 40, color: .green),
        ConstrainedSize(width: 20, height: 20, color: .red),
        ConstrainedSize(width: 30, height: 30, color: .blue),
        ConstrainedSize(width: 40, height: 40, color: .green),
        ConstrainedSize(width: 50, height: 20, color: .red),
        ConstrainedSize(width: 60, height: 30, color: .blue),
        ConstrainedSize(width: 70, height: 40, color: .green),
        ConstrainedSize(width: 80, height: 20, color: .red),
        ConstrainedSize(width: 90, height: 30, color: .blue),
        ConstrainedSize(width: 100, height: 40, color: .green),
    ]

    func test_aligned() {

        func flow(
            horizontalAlignment: Flow.HorizontalAlignment,
            rowAlignment: Flow.RowAlignment
        ) -> Element {
            Flow(
                horizontalAlignment: horizontalAlignment,
                horizontalSpacing: 10,
                rowAlignment: rowAlignment,
                rowSpacing: 5
            ) {
                Self.elements
            }
            .constrainedTo(width: .absolute(200))
        }

        for horizontalAlignment in Flow.HorizontalAlignment.allCases {
            for rowAlignment in Flow.RowAlignment.allCases {
                compareSnapshot(
                    of: flow(horizontalAlignment: horizontalAlignment, rowAlignment: rowAlignment),
                    identifier: "\(horizontalAlignment)_\(rowAlignment)"
                )
            }
        }
    }
}

extension ConstrainedSize {

    fileprivate init(width: CGFloat, height: CGFloat, color: UIColor) {
        self = Self(
            width: .absolute(width),
            height: .absolute(height),
            wrapping: Box(backgroundColor: color)
        )
    }

}
