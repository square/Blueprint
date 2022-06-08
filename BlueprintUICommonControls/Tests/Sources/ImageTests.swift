import BlueprintUI
import XCTest
@testable import BlueprintUICommonControls


class ImageTests: XCTestCase {

    private let image = UIImage(named: "test-image.jpg", in: .module, compatibleWith: nil)!

    func test_defaults() {
        let element = Image(image: image)
        XCTAssertEqual(element.contentMode, .aspectFill)
        XCTAssertNil(element.tintColor)
    }

    func test_measuring() {
        let element = Image(image: image)
        XCTAssertEqual(
            element.content.measure(in: SizeConstraint(width: .unconstrained, height: .unconstrained)),
            image.size
        )

    }

    func test_aspectFill() {
        var element = Image(image: image)
        element.contentMode = .aspectFill
        compareSnapshot(of: element, size: CGSize(width: 100, height: 100))
    }

    func test_aspectFit() {
        var element = Image(image: image)
        element.contentMode = .aspectFit
        compareSnapshot(of: element, size: CGSize(width: 100, height: 100))
    }

    func test_center() {
        var element = Image(image: image)
        element.contentMode = .center
        compareSnapshot(of: element, size: CGSize(width: 100, height: 100))
    }

    func test_stretch() {
        var element = Image(image: image)
        element.contentMode = .stretch
        compareSnapshot(of: element, size: CGSize(width: 100, height: 100))
    }

}
