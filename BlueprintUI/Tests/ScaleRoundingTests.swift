import XCTest
import BlueprintUI

final class ScaleRoundingTests: XCTestCase {
    func assert(
        _ x: Double,
        roundsTo expected: Double,
        rule: FloatingPointRoundingRule,
        scale: Double,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        var rounded: Double

        // non-mutating variant
        rounded = x.rounded(rule, by: scale)
        XCTAssertEqual(
            rounded,
            expected,
            accuracy: .ulpOfOne,
            "\(x) should round to \(expected) with rule: \(rule), scale: \(scale)",
            file: file,
            line: line
        )

        // mutating variant
        rounded = x
        rounded.round(rule, by: scale)
        XCTAssertEqual(
            rounded,
            expected,
            accuracy: .ulpOfOne,
            "\(x) should round to \(expected) with rule: \(rule), scale: \(scale)",
            file: file,
            line: line
        )
    }

    func test_scale1() {
        let scale = 1.0

        assert(0.0, roundsTo: 0.0, rule: .awayFromZero, scale: scale)
        assert(0.0, roundsTo: 0.0, rule: .down, scale: scale)
        assert(0.0, roundsTo: 0.0, rule: .toNearestOrAwayFromZero, scale: scale)
        assert(0.0, roundsTo: 0.0, rule: .toNearestOrEven, scale: scale)
        assert(0.0, roundsTo: 0.0, rule: .towardZero, scale: scale)
        assert(0.0, roundsTo: 0.0, rule: .up, scale: scale)

        assert(0.1, roundsTo: 1.0, rule: .awayFromZero, scale: scale)
        assert(0.1, roundsTo: 0.0, rule: .down, scale: scale)
        assert(0.1, roundsTo: 0.0, rule: .toNearestOrAwayFromZero, scale: scale)
        assert(0.1, roundsTo: 0.0, rule: .toNearestOrEven, scale: scale)
        assert(0.1, roundsTo: 0.0, rule: .towardZero, scale: scale)
        assert(0.1, roundsTo: 1.0, rule: .up, scale: scale)

        assert(0.5, roundsTo: 1.0, rule: .awayFromZero, scale: scale)
        assert(0.5, roundsTo: 0.0, rule: .down, scale: scale)
        assert(0.5, roundsTo: 1.0, rule: .toNearestOrAwayFromZero, scale: scale)
        assert(0.5, roundsTo: 0.0, rule: .toNearestOrEven, scale: scale)
        assert(0.5, roundsTo: 0.0, rule: .towardZero, scale: scale)
        assert(0.5, roundsTo: 1.0, rule: .up, scale: scale)

        assert(0.9, roundsTo: 1.0, rule: .awayFromZero, scale: scale)
        assert(0.9, roundsTo: 0.0, rule: .down, scale: scale)
        assert(0.9, roundsTo: 1.0, rule: .toNearestOrAwayFromZero, scale: scale)
        assert(0.9, roundsTo: 1.0, rule: .toNearestOrEven, scale: scale)
        assert(0.9, roundsTo: 0.0, rule: .towardZero, scale: scale)
        assert(0.9, roundsTo: 1.0, rule: .up, scale: scale)
    }

    func test_scale2() {
        let scale = 2.0

        assert(0.0, roundsTo: 0.0, rule: .awayFromZero, scale: scale)
        assert(0.0, roundsTo: 0.0, rule: .down, scale: scale)
        assert(0.0, roundsTo: 0.0, rule: .toNearestOrAwayFromZero, scale: scale)
        assert(0.0, roundsTo: 0.0, rule: .toNearestOrEven, scale: scale)
        assert(0.0, roundsTo: 0.0, rule: .towardZero, scale: scale)
        assert(0.0, roundsTo: 0.0, rule: .up, scale: scale)

        assert(0.1, roundsTo: 0.5, rule: .awayFromZero, scale: scale)
        assert(0.1, roundsTo: 0.0, rule: .down, scale: scale)
        assert(0.1, roundsTo: 0.0, rule: .toNearestOrAwayFromZero, scale: scale)
        assert(0.1, roundsTo: 0.0, rule: .toNearestOrEven, scale: scale)
        assert(0.1, roundsTo: 0.0, rule: .towardZero, scale: scale)
        assert(0.1, roundsTo: 0.5, rule: .up, scale: scale)

        assert(0.5, roundsTo: 0.5, rule: .awayFromZero, scale: scale)
        assert(0.5, roundsTo: 0.5, rule: .down, scale: scale)
        assert(0.5, roundsTo: 0.5, rule: .toNearestOrAwayFromZero, scale: scale)
        assert(0.5, roundsTo: 0.5, rule: .toNearestOrEven, scale: scale)
        assert(0.5, roundsTo: 0.5, rule: .towardZero, scale: scale)
        assert(0.5, roundsTo: 0.5, rule: .up, scale: scale)

        assert(0.9, roundsTo: 1.0, rule: .awayFromZero, scale: scale)
        assert(0.9, roundsTo: 0.5, rule: .down, scale: scale)
        assert(0.9, roundsTo: 1.0, rule: .toNearestOrAwayFromZero, scale: scale)
        assert(0.9, roundsTo: 1.0, rule: .toNearestOrEven, scale: scale)
        assert(0.9, roundsTo: 0.5, rule: .towardZero, scale: scale)
        assert(0.9, roundsTo: 1.0, rule: .up, scale: scale)
    }

    func test_scale3() {
        let scale = 3.0

        assert(0.0, roundsTo: 0.0, rule: .awayFromZero, scale: scale)
        assert(0.0, roundsTo: 0.0, rule: .down, scale: scale)
        assert(0.0, roundsTo: 0.0, rule: .toNearestOrAwayFromZero, scale: scale)
        assert(0.0, roundsTo: 0.0, rule: .toNearestOrEven, scale: scale)
        assert(0.0, roundsTo: 0.0, rule: .towardZero, scale: scale)
        assert(0.0, roundsTo: 0.0, rule: .up, scale: scale)

        assert(0.1, roundsTo: 1/3, rule: .awayFromZero, scale: scale)
        assert(0.1, roundsTo: 0.0, rule: .down, scale: scale)
        assert(0.1, roundsTo: 0.0, rule: .toNearestOrAwayFromZero, scale: scale)
        assert(0.1, roundsTo: 0.0, rule: .toNearestOrEven, scale: scale)
        assert(0.1, roundsTo: 0.0, rule: .towardZero, scale: scale)
        assert(0.1, roundsTo: 1/3, rule: .up, scale: scale)

        assert(0.5, roundsTo: 2/3, rule: .awayFromZero, scale: scale)
        assert(0.5, roundsTo: 1/3, rule: .down, scale: scale)
        assert(0.5, roundsTo: 2/3, rule: .toNearestOrAwayFromZero, scale: scale)
        assert(0.5, roundsTo: 2/3, rule: .toNearestOrEven, scale: scale)
        assert(0.5, roundsTo: 1/3, rule: .towardZero, scale: scale)
        assert(0.5, roundsTo: 2/3, rule: .up, scale: scale)

        assert(0.9, roundsTo: 1.0, rule: .awayFromZero, scale: scale)
        assert(0.9, roundsTo: 2/3, rule: .down, scale: scale)
        assert(0.9, roundsTo: 1.0, rule: .toNearestOrAwayFromZero, scale: scale)
        assert(0.9, roundsTo: 1.0, rule: .toNearestOrEven, scale: scale)
        assert(0.9, roundsTo: 2/3, rule: .towardZero, scale: scale)
        assert(0.9, roundsTo: 1.0, rule: .up, scale: scale)
    }
}
