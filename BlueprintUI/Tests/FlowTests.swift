import XCTest
@testable import BlueprintUI


class FlowTests: XCTestCase {

    private static let elements = [
        ConstrainedSize(width: 50, height: 5),
        ConstrainedSize(width: 100, height: 5),
        ConstrainedSize(width: 50, height: 5),
    ]


}


extension ConstrainedSize {

    fileprivate init(width: CGFloat, height: CGFloat) {
        self = Self(width: .absolute(width), height: .absolute(height), wrapping: Empty())
    }

}
