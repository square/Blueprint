import XCTest
@testable import BlueprintUI

final class RoundingScaleTests: XCTestCase {
    func assert(
        _ unrounded: CGFloat,
        roundsTo expected: CGFloat,
        rule: FloatingPointRoundingRule,
        scale: RoundingScale,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let rounded = scale.round(unrounded, rule)
        XCTAssertEqual(
            rounded,
            expected,
            accuracy: .ulpOfOne,
            "\(unrounded) should round to \(expected) with rule: \(rule), scale: \(scale)",
            file: file,
            line: line
        )
    }

    func test_scale1() {
        let scale = RoundingScale.scale(1.0)

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
        let scale = RoundingScale.scale(2.0)

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
        let scale = RoundingScale.scale(3.0)

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

    func test_none() {
        let scale = RoundingScale.none

        assert(0.0, roundsTo: 0.0, rule: .awayFromZero, scale: scale)
        assert(0.0, roundsTo: 0.0, rule: .down, scale: scale)
        assert(0.0, roundsTo: 0.0, rule: .toNearestOrAwayFromZero, scale: scale)
        assert(0.0, roundsTo: 0.0, rule: .toNearestOrEven, scale: scale)
        assert(0.0, roundsTo: 0.0, rule: .towardZero, scale: scale)
        assert(0.0, roundsTo: 0.0, rule: .up, scale: scale)

        assert(0.1, roundsTo: 0.1, rule: .awayFromZero, scale: scale)
        assert(0.1, roundsTo: 0.1, rule: .down, scale: scale)
        assert(0.1, roundsTo: 0.1, rule: .toNearestOrAwayFromZero, scale: scale)
        assert(0.1, roundsTo: 0.1, rule: .toNearestOrEven, scale: scale)
        assert(0.1, roundsTo: 0.1, rule: .towardZero, scale: scale)
        assert(0.1, roundsTo: 0.1, rule: .up, scale: scale)

        assert(0.5, roundsTo: 0.5, rule: .awayFromZero, scale: scale)
        assert(0.5, roundsTo: 0.5, rule: .down, scale: scale)
        assert(0.5, roundsTo: 0.5, rule: .toNearestOrAwayFromZero, scale: scale)
        assert(0.5, roundsTo: 0.5, rule: .toNearestOrEven, scale: scale)
        assert(0.5, roundsTo: 0.5, rule: .towardZero, scale: scale)
        assert(0.5, roundsTo: 0.5, rule: .up, scale: scale)

        assert(0.9, roundsTo: 0.9, rule: .awayFromZero, scale: scale)
        assert(0.9, roundsTo: 0.9, rule: .down, scale: scale)
        assert(0.9, roundsTo: 0.9, rule: .toNearestOrAwayFromZero, scale: scale)
        assert(0.9, roundsTo: 0.9, rule: .toNearestOrEven, scale: scale)
        assert(0.9, roundsTo: 0.9, rule: .towardZero, scale: scale)
        assert(0.9, roundsTo: 0.9, rule: .up, scale: scale)
    }
}
