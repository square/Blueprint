import XCTest
import BlueprintUI
@testable import BlueprintUICommonControls


class AttributedLabelTests: XCTestCase {

    func test_displaysText() {
        let string = NSAttributedString()
            .appending(string: "H", font: .boldSystemFont(ofSize: 24.0), color: .red)
            .appending(string: "e", font: .systemFont(ofSize: 14.0), color: .blue)
            .appending(string: "llo, ", font: .italicSystemFont(ofSize: 13.0), color: .magenta)
            .appending(string: "World!", font: .monospacedDigitSystemFont(ofSize: 32.0, weight: .black), color: .yellow)

        var element = AttributedLabel(attributedText: string)
        element.roundingScale = 1

        compareSnapshot(of: element)
        
    }

    func test_numberOfLines() {

        let string = NSAttributedString(string: "Hello, world. This is some long text that runs onto several lines.")
        var element = AttributedLabel(attributedText: string)
        element.roundingScale = 1

        element.numberOfLines = 0
        compareSnapshot(
            of: element,
            size: CGSize(width: 100, height: 800),
            identifier: "zero")

        element.numberOfLines = 1
        compareSnapshot(
            of: element,
            size: CGSize(width: 100, height: 800),
            identifier: "one")

        element.numberOfLines = 2
        compareSnapshot(
            of: element,
            size: CGSize(width: 100, height: 800),
            identifier: "two")
    }

    func test_measuring() {

        func test(in size: CGSize, file: StaticString = #file, line: UInt = #line) {

            let string = NSAttributedString()
                .appending(string: "H", font: .boldSystemFont(ofSize: 24.0), color: .red)
                .appending(string: "e", font: .systemFont(ofSize: 14.0), color: .blue)
                .appending(string: "llo, ", font: .italicSystemFont(ofSize: 13.0), color: .magenta)
                .appending(string: "World!", font: .monospacedDigitSystemFont(ofSize: 32.0, weight: .black), color: .yellow)

            var element = AttributedLabel(attributedText: string)
            element.roundingScale = 1

            var measuredSize = string.boundingRect(with: size, options: .usesLineFragmentOrigin, context: nil).size
            measuredSize.width = measuredSize.width.rounded(.up)
            measuredSize.height = measuredSize.height.rounded(.up)

            let elementSize = element.content.measure(in: SizeConstraint(size))

            XCTAssertEqual(measuredSize, elementSize, file: file, line: line)
        }

        test(in: CGSize(width: 30, height: 20))
        test(in: CGSize(width: 100, height: 300))
        test(in: CGSize(width: 120, height: 300))
        test(in: CGSize(width: 8000, height: 4000))

    }

    func test_rounding() {
        let string = NSAttributedString(
            string: "iiiii",
            attributes: [
                .font: UIFont.systemFont(ofSize: 23)
            ])

        var element = AttributedLabel(attributedText: string)
        element.roundingScale = 2.0

        let size = element.content.measure(in: SizeConstraint(CGSize(width: 100, height: 100)))

        XCTAssertEqual(size, CGSize(width: 25.5, height: 27.5))
    }
}


extension NSAttributedString {

    func appending(string: String, font: UIFont, color: UIColor) -> NSAttributedString {
        let mutableResult = NSMutableAttributedString(attributedString: self)
        let stringToAppend = NSAttributedString(
            string: string,
            attributes: [
                NSAttributedString.Key.font: font,
                NSAttributedString.Key.foregroundColor: color
            ])
        mutableResult.append(stringToAppend)
        return NSAttributedString(attributedString: mutableResult)
    }

}
