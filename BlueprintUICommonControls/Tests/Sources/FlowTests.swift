import BlueprintUICommonControls
import XCTest
@testable import BlueprintUI


/// Note; While `Flow` lives in `BlueprintUI`, we're putting some snapshot tests in
/// `BlueprintUICommonControls` for easier verification of the layout.

class FlowTests: XCTestCase {

    func test_aligned() {

        func flow(
            lineAlignment: Flow.LineAlignment,
            itemAlignment: Flow.ItemAlignment
        ) -> Element {
            Flow(
                lineAlignment: lineAlignment,
                lineSpacing: 10,
                itemAlignment: itemAlignment,
                itemSpacing: 2
            ) {
                ConstrainedSize(width: 50, height: 40, color: .green)
                ConstrainedSize(width: 20, height: 20, color: .red)
                ConstrainedSize(width: 30, height: 30, color: .blue)
                ConstrainedSize(width: 40, height: 40, color: .green)
                ConstrainedSize(width: 50, height: 20, color: .red)
                ConstrainedSize(width: 60, height: 30, color: .blue)
                ConstrainedSize(width: 70, height: 40, color: .green)
                ConstrainedSize(width: 80, height: 20, color: .red)
                ConstrainedSize(width: 90, height: 30, color: .blue)
                ConstrainedSize(width: 100, height: 40, color: .green)
            }
            .constrainedTo(width: .absolute(200))
        }

        for lineAlignment in Flow.LineAlignment.allCases {
            for itemAlignment in Flow.ItemAlignment.allCases {
                compareSnapshot(
                    of: flow(lineAlignment: lineAlignment, itemAlignment: itemAlignment),
                    identifier: "\(lineAlignment)_\(itemAlignment)"
                )
            }
        }
    }

    func test_tooWide() {

        let flow = Flow(lineSpacing: 5) {
            ConstrainedSize(width: 110, height: 40, color: .green)
            ConstrainedSize(width: 120, height: 20, color: .red)
            ConstrainedSize(width: 130, height: 30, color: .blue)
        }
        .constrainedTo(width: .absolute(100))

        compareSnapshot(of: flow)
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
