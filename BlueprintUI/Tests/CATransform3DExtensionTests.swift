import XCTest
@testable import BlueprintUI

class CATransform3DExtensionTests: XCTestCase {

    func testSimdRoundTrip() {
        var transform = CATransform3DIdentity
        transform = CATransform3DRotate(transform, 2.0, 1.0, 0.0, 0.0)

        let matrix = transform.double4x4Value
        let recreatedTransform = CATransform3D(matrix)

        XCTAssertEqual(transform, recreatedTransform)

    }

}
