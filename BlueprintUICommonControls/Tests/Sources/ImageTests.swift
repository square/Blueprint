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

    func test_measure_aspectFill() {
        func validate(
            size: CGSize,
            constraint: SizeConstraint,
            expectedValue: CGSize,
            line: UInt = #line
        ) {
            self.validate(
                contentMode: .aspectFill,
                imageSize: size,
                constraint: constraint,
                expectedValue: expectedValue,
                line: line
            )
        }

        // Wide aspect ratio image

        validate(
            size: .init(width: 20, height: 10),
            constraint: .init(width: .unconstrained, height: .unconstrained),
            expectedValue: .init(width: 20, height: 10)
        )

        validate(
            size: .init(width: 20, height: 10),
            constraint: .init(width: .atMost(40), height: .unconstrained),
            expectedValue: .init(width: 40, height: 20)
        )

        validate(
            size: .init(width: 20, height: 10),
            constraint: .init(width: .atMost(10), height: .unconstrained),
            expectedValue: .init(width: 10, height: 5)
        )

        validate(
            size: .init(width: 20, height: 10),
            constraint: .init(width: .atMost(5), height: .atMost(5)),
            expectedValue: .init(width: 5, height: 2.5)
        )

        validate(
            size: .init(width: 20, height: 10),
            constraint: .init(width: .atMost(40), height: .atMost(40)),
            expectedValue: .init(width: 40, height: 20)
        )

        validate(
            size: .init(width: 20, height: 10),
            constraint: .init(width: .atMost(40), height: .atMost(10)),
            expectedValue: .init(width: 20, height: 10)
        )

        validate(
            size: .init(width: 20, height: 10),
            constraint: .init(width: .unconstrained, height: .atMost(100)),
            expectedValue: .init(width: 200, height: 100)
        )

        validate(
            size: .init(width: 20, height: 10),
            constraint: .init(width: .unconstrained, height: .atMost(1)),
            expectedValue: .init(width: 2, height: 1)
        )

        // Tall aspect ratio image

        validate(
            size: .init(width: 10, height: 20),
            constraint: .init(width: .unconstrained, height: .unconstrained),
            expectedValue: .init(width: 10, height: 20)
        )

        validate(
            size: .init(width: 10, height: 20),
            constraint: .init(width: .atMost(100), height: .unconstrained),
            expectedValue: .init(width: 100, height: 200)
        )

        validate(
            size: .init(width: 10, height: 20),
            constraint: .init(width: .atMost(5), height: .unconstrained),
            expectedValue: .init(width: 5, height: 10)
        )

        validate(
            size: .init(width: 10, height: 20),
            constraint: .init(width: .atMost(5), height: .atMost(5)),
            expectedValue: .init(width: 2.5, height: 5)
        )

        validate(
            size: .init(width: 10, height: 20),
            constraint: .init(width: .atMost(40), height: .atMost(40)),
            expectedValue: .init(width: 20, height: 40)
        )

        validate(
            size: .init(width: 10, height: 20),
            constraint: .init(width: .atMost(10), height: .atMost(40)),
            expectedValue: .init(width: 10, height: 20)
        )

        validate(
            size: .init(width: 10, height: 20),
            constraint: .init(width: .unconstrained, height: .atMost(100)),
            expectedValue: .init(width: 50, height: 100)
        )

        validate(
            size: .init(width: 10, height: 20),
            constraint: .init(width: .unconstrained, height: .atMost(4)),
            expectedValue: .init(width: 2, height: 4)
        )
    }

    func test_measure_aspectFit() {
        func validate(
            size: CGSize,
            constraint: SizeConstraint,
            expectedValue: CGSize,
            line: UInt = #line
        ) {
            self.validate(
                contentMode: .aspectFit,
                imageSize: size,
                constraint: constraint,
                expectedValue: expectedValue,
                line: line
            )
        }

        // Wide aspect ratio image

        validate(
            size: .init(width: 20, height: 10),
            constraint: .init(width: .unconstrained, height: .unconstrained),
            expectedValue: .init(width: 20, height: 10)
        )

        validate(
            size: .init(width: 20, height: 10),
            constraint: .init(width: .atMost(40), height: .unconstrained),
            expectedValue: .init(width: 40, height: 20)
        )

        validate(
            size: .init(width: 20, height: 10),
            constraint: .init(width: .atMost(10), height: .unconstrained),
            expectedValue: .init(width: 10, height: 5)
        )

        validate(
            size: .init(width: 20, height: 10),
            constraint: .init(width: .atMost(8), height: .atMost(8)),
            expectedValue: .init(width: 8, height: 4)
        )

        validate(
            size: .init(width: 20, height: 10),
            constraint: .init(width: .atMost(40), height: .atMost(40)),
            expectedValue: .init(width: 40, height: 20)
        )

        validate(
            size: .init(width: 20, height: 10),
            constraint: .init(width: .atMost(40), height: .atMost(10)),
            expectedValue: .init(width: 20, height: 10)
        )

        validate(
            size: .init(width: 20, height: 10),
            constraint: .init(width: .unconstrained, height: .atMost(100)),
            expectedValue: .init(width: 200, height: 100)
        )

        validate(
            size: .init(width: 20, height: 10),
            constraint: .init(width: .unconstrained, height: .atMost(1)),
            expectedValue: .init(width: 2, height: 1)
        )

        // Tall aspect ratio image

        validate(
            size: .init(width: 10, height: 20),
            constraint: .init(width: .unconstrained, height: .unconstrained),
            expectedValue: .init(width: 10, height: 20)
        )

        validate(
            size: .init(width: 10, height: 20),
            constraint: .init(width: .atMost(100), height: .unconstrained),
            expectedValue: .init(width: 100, height: 200)
        )

        validate(
            size: .init(width: 10, height: 20),
            constraint: .init(width: .atMost(5), height: .unconstrained),
            expectedValue: .init(width: 5, height: 10)
        )

        validate(
            size: .init(width: 10, height: 20),
            constraint: .init(width: .atMost(5), height: .atMost(8)),
            expectedValue: .init(width: 4, height: 8)
        )

        validate(
            size: .init(width: 10, height: 20),
            constraint: .init(width: .atMost(40), height: .atMost(40)),
            expectedValue: .init(width: 20, height: 40)
        )

        validate(
            size: .init(width: 10, height: 20),
            constraint: .init(width: .atMost(10), height: .atMost(40)),
            expectedValue: .init(width: 10, height: 20)
        )

        validate(
            size: .init(width: 10, height: 20),
            constraint: .init(width: .unconstrained, height: .atMost(100)),
            expectedValue: .init(width: 50, height: 100)
        )

        validate(
            size: .init(width: 10, height: 20),
            constraint: .init(width: .unconstrained, height: .atMost(4)),
            expectedValue: .init(width: 2, height: 4)
        )
    }

    func test_measure_center() {
        func validate(
            size: CGSize,
            constraint: SizeConstraint,
            expectedValue: CGSize,
            line: UInt = #line
        ) {
            self.validate(
                contentMode: .center,
                imageSize: size,
                constraint: constraint,
                expectedValue: expectedValue,
                line: line
            )
        }

        // Wide aspect ratio image

        validate(
            size: .init(width: 20, height: 10),
            constraint: .init(width: .unconstrained, height: .unconstrained),
            expectedValue: .init(width: 20, height: 10)
        )

        validate(
            size: .init(width: 20, height: 10),
            constraint: .init(width: .atMost(40), height: .unconstrained),
            expectedValue: .init(width: 20, height: 10)
        )

        validate(
            size: .init(width: 20, height: 10),
            constraint: .init(width: .atMost(10), height: .unconstrained),
            expectedValue: .init(width: 20, height: 10)
        )

        validate(
            size: .init(width: 20, height: 10),
            constraint: .init(width: .atMost(8), height: .atMost(8)),
            expectedValue: .init(width: 20, height: 10)
        )

        validate(
            size: .init(width: 20, height: 10),
            constraint: .init(width: .atMost(40), height: .atMost(40)),
            expectedValue: .init(width: 20, height: 10)
        )

        validate(
            size: .init(width: 20, height: 10),
            constraint: .init(width: .atMost(40), height: .atMost(10)),
            expectedValue: .init(width: 20, height: 10)
        )

        validate(
            size: .init(width: 20, height: 10),
            constraint: .init(width: .unconstrained, height: .atMost(100)),
            expectedValue: .init(width: 20, height: 10)
        )

        validate(
            size: .init(width: 20, height: 10),
            constraint: .init(width: .unconstrained, height: .atMost(1)),
            expectedValue: .init(width: 20, height: 10)
        )

        // Tall aspect ratio image

        validate(
            size: .init(width: 10, height: 20),
            constraint: .init(width: .unconstrained, height: .unconstrained),
            expectedValue: .init(width: 10, height: 20)
        )

        validate(
            size: .init(width: 10, height: 20),
            constraint: .init(width: .atMost(100), height: .unconstrained),
            expectedValue: .init(width: 10, height: 20)
        )

        validate(
            size: .init(width: 10, height: 20),
            constraint: .init(width: .atMost(5), height: .unconstrained),
            expectedValue: .init(width: 10, height: 20)
        )

        validate(
            size: .init(width: 10, height: 20),
            constraint: .init(width: .atMost(5), height: .atMost(8)),
            expectedValue: .init(width: 10, height: 20)
        )

        validate(
            size: .init(width: 10, height: 20),
            constraint: .init(width: .atMost(40), height: .atMost(40)),
            expectedValue: .init(width: 10, height: 20)
        )

        validate(
            size: .init(width: 10, height: 20),
            constraint: .init(width: .atMost(40), height: .atMost(10)),
            expectedValue: .init(width: 10, height: 20)
        )

        validate(
            size: .init(width: 10, height: 20),
            constraint: .init(width: .unconstrained, height: .atMost(100)),
            expectedValue: .init(width: 10, height: 20)
        )

        validate(
            size: .init(width: 10, height: 20),
            constraint: .init(width: .unconstrained, height: .atMost(4)),
            expectedValue: .init(width: 10, height: 20)
        )
    }

    func test_measure_stretch() {
        func validate(
            size: CGSize,
            constraint: SizeConstraint,
            expectedValue: CGSize,
            line: UInt = #line
        ) {
            self.validate(
                contentMode: .stretch,
                imageSize: size,
                constraint: constraint,
                expectedValue: expectedValue,
                line: line
            )
        }

        // Wide aspect ratio image

        validate(
            size: .init(width: 20, height: 10),
            constraint: .init(width: .unconstrained, height: .unconstrained),
            expectedValue: .init(width: 20, height: 10)
        )

        validate(
            size: .init(width: 20, height: 10),
            constraint: .init(width: .atMost(40), height: .unconstrained),
            expectedValue: .init(width: 20, height: 10)
        )

        validate(
            size: .init(width: 20, height: 10),
            constraint: .init(width: .atMost(10), height: .unconstrained),
            expectedValue: .init(width: 20, height: 10)
        )

        validate(
            size: .init(width: 20, height: 10),
            constraint: .init(width: .atMost(8), height: .atMost(8)),
            expectedValue: .init(width: 20, height: 10)
        )

        validate(
            size: .init(width: 20, height: 10),
            constraint: .init(width: .atMost(40), height: .atMost(40)),
            expectedValue: .init(width: 20, height: 10)
        )

        validate(
            size: .init(width: 20, height: 10),
            constraint: .init(width: .atMost(40), height: .atMost(10)),
            expectedValue: .init(width: 20, height: 10)
        )

        validate(
            size: .init(width: 20, height: 10),
            constraint: .init(width: .unconstrained, height: .atMost(100)),
            expectedValue: .init(width: 20, height: 10)
        )

        validate(
            size: .init(width: 20, height: 10),
            constraint: .init(width: .unconstrained, height: .atMost(1)),
            expectedValue: .init(width: 20, height: 10)
        )

        // Tall aspect ratio image

        validate(
            size: .init(width: 10, height: 20),
            constraint: .init(width: .unconstrained, height: .unconstrained),
            expectedValue: .init(width: 10, height: 20)
        )

        validate(
            size: .init(width: 10, height: 20),
            constraint: .init(width: .atMost(100), height: .unconstrained),
            expectedValue: .init(width: 10, height: 20)
        )

        validate(
            size: .init(width: 10, height: 20),
            constraint: .init(width: .atMost(5), height: .unconstrained),
            expectedValue: .init(width: 10, height: 20)
        )

        validate(
            size: .init(width: 10, height: 20),
            constraint: .init(width: .atMost(5), height: .atMost(8)),
            expectedValue: .init(width: 10, height: 20)
        )

        validate(
            size: .init(width: 10, height: 20),
            constraint: .init(width: .atMost(40), height: .atMost(40)),
            expectedValue: .init(width: 10, height: 20)
        )

        validate(
            size: .init(width: 10, height: 20),
            constraint: .init(width: .atMost(40), height: .atMost(10)),
            expectedValue: .init(width: 10, height: 20)
        )

        validate(
            size: .init(width: 10, height: 20),
            constraint: .init(width: .unconstrained, height: .atMost(100)),
            expectedValue: .init(width: 10, height: 20)
        )

        validate(
            size: .init(width: 10, height: 20),
            constraint: .init(width: .unconstrained, height: .atMost(4)),
            expectedValue: .init(width: 10, height: 20)
        )
    }

    private func validate(
        contentMode: Image.ContentMode,
        imageSize: CGSize,
        constraint: SizeConstraint,
        expectedValue: CGSize,
        line: UInt = #line
    ) {
        let image = UIImage.test(imageSize)
        let element = Image(
            image: image,
            contentMode: contentMode
        )

        XCTAssertEqual(
            element.content.measure(in: constraint),
            expectedValue,
            """
            Image in content mode: \(contentMode),
            of size (\(Int(imageSize.width))x\(Int(imageSize.height)))
            expected to be measured as (\(Int(expectedValue.width))x\(Int(expectedValue.height)))
            in constraint: (\(constraint))
            """,
            line: line
        )
    }
}


extension UIImage {

    fileprivate static func test(_ size: CGSize) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { rendererContext in
            UIColor.red.setFill()
            rendererContext.fill(CGRect(origin: .zero, size: size))
        }
    }
}
