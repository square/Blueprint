import XCTest
import BlueprintUI
@testable import BlueprintUICommonControls

class RuleTests: XCTestCase {
    func test_horizontal() {
        let rule = Rule(orientation: .horizontal, color: .red, thickness: .points(2))
        let column = Column { column in
            column.horizontalAlignment = .fill
            column.add(child: Spacer(size: CGSize(width: 10, height: 10)))
            column.add(child: rule)
            column.add(child: Spacer(size: CGSize(width: 10, height: 10)))
        }
        compareSnapshot(of: column)
    }

    func test_vertical() {
        let rule = Rule(orientation: .vertical, color: .blue, thickness: .points(3))
        let row = Row { row in
            row.verticalAlignment = .fill
            row.add(child: Spacer(size: CGSize(width: 10, height: 10)))
            row.add(child: rule)
            row.add(child: Spacer(size: CGSize(width: 10, height: 10)))
        }
        compareSnapshot(of: row)
    }

    func test_hairline() {
        let rule = Rule(orientation: .horizontal, color: .black, thickness: .hairline)
        let size = rule.content.measure(in: SizeConstraint(CGSize(width: 10, height: 10)))
        XCTAssertEqual(size, CGSize(width: 0, height: 1.0 / UIScreen.main.scale))
    }
}
