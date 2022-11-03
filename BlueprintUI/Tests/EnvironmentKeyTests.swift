import XCTest
@testable import BlueprintUI

final class EnvironmentKeyTests: XCTestCase {
    func test_isEquivalent() {
        XCTAssertTrue(EquatableKey.isEquivalent(1, 1))
        XCTAssertFalse(EquatableKey.isEquivalent(1, 2))
    }

    func test_areValuesEqual() {
        XCTAssertTrue(EquatableKey.areValuesEqual(1, 1))
        XCTAssertFalse(EquatableKey.areValuesEqual(1, 2))
    }
}

fileprivate struct EquatableKey: EnvironmentKey, Equatable {
    typealias Value = Int
    static let defaultValue: Int = 1
}
