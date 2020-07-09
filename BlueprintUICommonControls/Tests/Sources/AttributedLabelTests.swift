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

        let element = AttributedLabel(attributedText: string)

        compareSnapshot(of: element)
        
    }

    func test_numberOfLines() {

        let string = NSAttributedString(string: "Hello, world. This is some long text that runs onto several lines.")
        var element = AttributedLabel(attributedText: string)

        func constrained() -> Element {
            element.constrainedTo(width: .atMost(100), height: .atMost(800))
        }

        element.numberOfLines = 0
        compareSnapshot(
            of: constrained(),
            identifier: "zero")

        element.numberOfLines = 1
        compareSnapshot(
            of: constrained(),
            identifier: "one")

        element.numberOfLines = 2
        compareSnapshot(
            of: constrained(),
            identifier: "two")
    }

    func test_measuring() {

        func test(in size: CGSize, expectedSize: CGSize, file: StaticString = #file, line: UInt = #line) {
            let string = NSAttributedString()
                .appending(string: "H", font: .boldSystemFont(ofSize: 24.0), color: .red)
                .appending(string: "e", font: .systemFont(ofSize: 14.0), color: .blue)
                .appending(string: "llo, ", font: .italicSystemFont(ofSize: 13.0), color: .magenta)
                .appending(string: "World!", font: .monospacedDigitSystemFont(ofSize: 32.0, weight: .black), color: .yellow)

            let element = AttributedLabel(attributedText: string)

            let elementSize = element.content.measure(in: SizeConstraint(size))
            XCTAssertEqual(expectedSize, elementSize, file: file, line: line)
        }

        test(
            in: CGSize(width: 30, height: 20),
            expectedSize: CGSize(width: 30, height: 235.5))
        test(
            in: CGSize(width: 100, height: 300),
            expectedSize: CGSize(width: 95, height: 105.5))
        test(
            in: CGSize(width: 120, height: 300),
            expectedSize: CGSize(width: 107, height: 67))
        test(
            in: CGSize(width: 8000, height: 4000),
            expectedSize: CGSize(width: 153.5, height: 38.5))

    }

    func test_textRectOffset() {
        let lineHeight: CGFloat = 50
        let font = UIFont.systemFont(ofSize: 17)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = lineHeight
        paragraphStyle.maximumLineHeight = lineHeight

        let string = NSAttributedString(
            string: "This text should be centered within the line height", attributes: [
                .font: font,
                .paragraphStyle: paragraphStyle
            ]
        )

        let offset = (font.lineHeight - lineHeight) / 2

        var label = AttributedLabel(attributedText: string)
        label.textRectOffset = UIOffset(horizontal: 0, vertical: offset)

        let element = ConstrainedSize(width: .atMost(150), wrapping: label)
        compareSnapshot(of: element)
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
