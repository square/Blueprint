import XCTest
import Blueprint
@testable import BlueprintCommonControls


class AttributedLabelTests: XCTestCase {

    func test_displaysText() {
        let string = NSAttributedString()
            .appending(string: "H", font: .boldSystemFont(ofSize: 24.0), color: .red)
            .appending(string: "e", font: .systemFont(ofSize: 14.0), color: .blue)
            .appending(string: "llo, ", font: .italicSystemFont(ofSize: 13.0), color: .magenta)
            .appending(string: "World!", font: .monospacedDigitSystemFont(ofSize: 32.0, weight: .black), color: .yellow)

        let element = AttributedLabel(attributedText: string)

        compareSnapshot(of: element)
        
    }

    func test_numberOfLines() {

        let string = NSAttributedString(string: "Hello, world. This is some long text that runs onto several lines.")
        var element = AttributedLabel(attributedText: string)

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

            let element = AttributedLabel(attributedText: string)

            var measuredSize = string.boundingRect(with: size, options: .usesLineFragmentOrigin, context: nil).size
            measuredSize.width = ceil(measuredSize.width)
            measuredSize.height = ceil(measuredSize.height)

            let elementSize = element.content.measure(in: SizeConstraint(size))

            XCTAssertEqual(measuredSize, elementSize, file: file, line: line)
        }

        test(in: CGSize(width: 30, height: 20))
        test(in: CGSize(width: 100, height: 300))
        test(in: CGSize(width: 120, height: 300))
        test(in: CGSize(width: 8000, height: 4000))

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
