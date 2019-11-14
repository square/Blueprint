import XCTest
import BlueprintUI
@testable import BlueprintUICommonControls


class ImageTests: XCTestCase {

    private let image: UIImage = {
        
        func getImageURL(file: StaticString = #file) -> URL {
            if let url = Bundle(for: ImageTests.self).url(forResource: "test-image", withExtension: "jpg") {
                return url
            } else {
                var path = NSString(stringLiteral: file)
                path = path.deletingLastPathComponent as NSString // filename
                path = path.deletingLastPathComponent as NSString // `Sources`
                path = path.appendingPathComponent("Resources") as NSString
                path = path.appendingPathComponent("test-image.jpg") as NSString
                return URL(fileURLWithPath: path as String)
            }
        }
        
        let imageURL = getImageURL()
        return UIImage(contentsOfFile: imageURL.path)!
    }()

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
