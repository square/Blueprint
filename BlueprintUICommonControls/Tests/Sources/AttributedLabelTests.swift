import BlueprintUI
import XCTest
@testable import BlueprintUICommonControls


class AttributedLabelTests: XCTestCase {

    func test_accessibilityTraits() {

        let string = NSAttributedString(string: "Hello, World!")

        let defaultTraits = AttributedLabel(attributedText: string)

        let nilTraits = AttributedLabel(attributedText: string) { label in
            label.accessibilityTraits = nil
        }

        let noTraits = AttributedLabel(attributedText: string) { label in
            label.accessibilityTraits = []
        }

        let header = AttributedLabel(attributedText: string) { label in
            label.accessibilityTraits = [.header]
        }

        let headerAndStatic = AttributedLabel(attributedText: string) { label in
            label.accessibilityTraits = [.header, .staticText]
        }

        let updatesFrequently = AttributedLabel(attributedText: string) { label in
            label.accessibilityTraits = [.header, .updatesFrequently]
        }

        let view = BlueprintView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))

        defaultTraits.accessBackingView(in: view) { label in
            let label = label as! UILabel

            XCTAssertEqual(label.accessibilityTraits, [])
        }

        nilTraits.accessBackingView(in: view) { label in
            let label = label as! UILabel

            XCTAssertEqual(label.accessibilityTraits, [])
        }

        noTraits.accessBackingView(in: view) { label in
            let label = label as! UILabel

            XCTAssertEqual(label.accessibilityTraits, [])
        }

        header.accessBackingView(in: view) { label in
            let label = label as! UILabel

            XCTAssertEqual(label.accessibilityTraits, [.header])
        }

        headerAndStatic.accessBackingView(in: view) { label in
            let label = label as! UILabel

            XCTAssertEqual(label.accessibilityTraits, [.header, .staticText])
        }

        updatesFrequently.accessBackingView(in: view) { label in
            let label = label as! UILabel

            XCTAssertEqual(label.accessibilityTraits, [.header, .updatesFrequently])
        }
    }

    func test_displaysText() {
        let string = NSAttributedString()
            .appending(string: "H", font: .boldSystemFont(ofSize: 24.0), color: .red)
            .appending(string: "e", font: .systemFont(ofSize: 14.0), color: .blue)
            .appending(string: "llo, ", font: .italicSystemFont(ofSize: 13.0), color: .magenta)
            .appending(string: "World!", font: .monospacedDigitSystemFont(ofSize: 32.0, weight: .black), color: .yellow)

        let element = AttributedLabel(attributedText: string)

        compareSnapshot(of: element)

    }

    func test_shadows() {
        let string = NSAttributedString(
            string: "Spooky text",
            attributes: [
                .font: UIFont.boldSystemFont(ofSize: 24),
            ]
        )

        let element = AttributedLabel(attributedText: string) { label in
            label.shadow = TextShadow(
                radius: 4,
                opacity: 0.75,
                offset: UIOffset(horizontal: 1, vertical: 4),
                color: .red
            )
        }.inset(uniform: 8)

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
            identifier: "zero"
        )

        element.numberOfLines = 1
        compareSnapshot(
            of: constrained(),
            identifier: "one"
        )

        element.numberOfLines = 2
        compareSnapshot(
            of: constrained(),
            identifier: "two"
        )
    }

    func test_fontSizeAdjustment() {

        let element = AttributedLabel(attributedText: NSAttributedString(string: "Hello! What's up y'all")) {
            $0.adjustsFontSizeToFitWidth = true
            $0.minimumScaleFactor = 0.5

            $0.numberOfLines = 1
        }

        compareSnapshot(
            of: element.constrainedTo(width: .unconstrained),
            identifier: "all_fits"
        )

        compareSnapshot(
            of: element.constrainedTo(width: .atMost(100)),
            identifier: "squishes"
        )

        compareSnapshot(
            of: element.constrainedTo(width: .atMost(50)),
            identifier: "overflows"
        )
    }

    func test_measuring() {

        func test(in size: CGSize, expectedSize: CGSize, file: StaticString = #file, line: UInt = #line) {
            let string = NSAttributedString()
                .appending(string: "H", font: .boldSystemFont(ofSize: 24.0), color: .red)
                .appending(string: "e", font: .systemFont(ofSize: 14.0), color: .blue)
                .appending(string: "llo, ", font: .italicSystemFont(ofSize: 13.0), color: .magenta)
                .appending(
                    string: "World!",
                    font: .monospacedDigitSystemFont(ofSize: 32.0, weight: .black),
                    color: .yellow
                )

            var label = AttributedLabel(attributedText: string)

            XCTAssertEqual(
                expectedSize,
                label.content.measure(in: SizeConstraint(size)),
                file: file,
                line: line
            )

            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.5

            XCTAssertEqual(
                expectedSize,
                label.content.measure(in: SizeConstraint(size)),
                file: file,
                line: line
            )
        }

        test(
            in: CGSize(width: 30, height: 20),
            expectedSize: CGSize(width: 30, height: 235.5)
        )
        test(
            in: CGSize(width: 100, height: 300),
            expectedSize: CGSize(width: 95, height: 105.5)
        )
        test(
            in: CGSize(width: 120, height: 300),
            expectedSize: CGSize(width: 107, height: 67)
        )
        test(
            in: CGSize(width: 8000, height: 4000),
            expectedSize: CGSize(width: 153.5, height: 38.5)
        )
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
                .paragraphStyle: paragraphStyle,
            ]
        )

        let offset = (font.lineHeight - lineHeight) / 2

        var label = AttributedLabel(attributedText: string)
        label.textRectOffset = UIOffset(horizontal: 0, vertical: offset)

        let element = ConstrainedSize(width: .atMost(150), wrapping: label)
        compareSnapshot(of: element)
    }

    func test_pixelSnappingDoesNotCauseTruncation() {
        // Offset by a big enough number to force loss of precision
        let offset = CGFloat(2 << 15)

        let element = Label(text: "Sample text should not get cut off") {
            $0.lineBreakMode = .byTruncatingTail
            $0.numberOfLines = 1
        }
        .inset(uniform: offset)
        .inset(uniform: -offset)
        .centered()

        compareSnapshot(
            of: element,
            size: CGSize(width: 400, height: 100),
            scale: UIScreen.main.scale
        )
    }

    func test_linkDetection() {
        let string = NSAttributedString(string: "Phone: (555) 555-5555 Address: 1455 Market St URL: https://block.xyz Date: 12/1/12")
        let element = AttributedLabel(attributedText: string) {
            $0.linkDetectionTypes = [.link, .address, .phoneNumber, .date]
        }

        compareSnapshot(of: element)
    }

    func test_linkAttribute() {
        let string = NSAttributedString(string: "Some text", attributes: [.link: URL(string: "https://block.xyz")!])
        let element = AttributedLabel(attributedText: string) {
            $0.linkAttributes = [.foregroundColor: UIColor.red, .backgroundColor: UIColor.black]
        }

        compareSnapshot(of: element)
    }

    func test_textContainerRects() {
        let lineBreakModes: [NSLineBreakMode?] = [
            nil,
            .byCharWrapping,
            .byWordWrapping,
            .byClipping,
            .byTruncatingHead,
            .byTruncatingMiddle,
            .byTruncatingTail,
        ]

        let numberOfLines = [
            0,
            1,
            2,
        ]

        let lineHeights: [CGFloat?] = [
            nil,
            50,
        ]

        let widths: [CGFloat] = [
            320,
            375,
        ]

        let text = """
        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed eiusmod tempor incididunt ut labore dolore magna aliqua. Ut enim minim veniam, quis nostrud exercitation ullamco laboris nisi aliquip ea commodo consequat.
        """

        for lineBreakMode in lineBreakModes {
            let mode = lineBreakMode.flatMap { $0.description } ?? "None"
            for lineHeight in lineHeights {
                let height = lineHeight.flatMap { $0.description } ?? "None"
                for lineCount in numberOfLines {
                    for width in widths {
                        let identifier = "\(mode)_\(lineCount)-lines_lineheight-\(height)_width-\(width)"
                        var attributedText = AttributedText(text)

                        for word in attributedText.string.split(separator: " ") {
                            let range = attributedText.range(of: word)!
                            attributedText[range].link = URL(string: "https://link.com")!
                        }

                        let paragraphStyle = NSMutableParagraphStyle()

                        if let lineBreakMode = lineBreakMode {
                            paragraphStyle.lineBreakMode = lineBreakMode
                            attributedText.paragraphStyle = paragraphStyle
                        }

                        if let lineHeight = lineHeight {
                            paragraphStyle.minimumLineHeight = lineHeight
                            paragraphStyle.maximumLineHeight = lineHeight
                            attributedText.paragraphStyle = paragraphStyle
                        }

                        let label = AttributedLabel(attributedText: attributedText.attributedString) { label in
                            label.numberOfLines = lineCount
                            if let lineHeight = lineHeight {
                                let fontLineHeight = UIFont.systemFont(ofSize: UIFont.labelFontSize).lineHeight
                                label.textRectOffset = .init(horizontal: 0, vertical: -(lineHeight - fontLineHeight) / 2)
                            }
                        }
                        let textContainer = TextContainerBox(model: label)

                        let element = Overlay {
                            textContainer
                            label
                        }

                        compareSnapshot(
                            of: element.constrainedTo(width: .atMost(CGFloat(width))),
                            identifier: identifier
                        )
                    }
                }
            }
        }
    }

    func testTextContainerLineBreakMode() {
        let wrappingModes: [NSLineBreakMode] = [
            .byCharWrapping,
            .byWordWrapping,
        ]

        let nonWrappingModes: [NSLineBreakMode] = [
            .byClipping,
            .byTruncatingHead,
            .byTruncatingMiddle,
            .byTruncatingTail,
        ]

        let numberOfLines = [
            0,
            1,
            2,
        ]

        for mode in wrappingModes {
            for lineCount in numberOfLines {
                let effectiveMode = mode.textContainerMode(for: lineCount)
                if lineCount == 1 {
                    XCTAssertEqual(.byClipping, effectiveMode)
                } else {
                    XCTAssertEqual(mode, effectiveMode)
                }
            }
        }

        for mode in nonWrappingModes {
            for lineCount in numberOfLines {
                let effectiveMode = mode.textContainerMode(for: lineCount)
                if lineCount == 1 {
                    XCTAssertEqual(mode, effectiveMode)
                } else {
                    XCTAssertEqual(.byWordWrapping, effectiveMode)
                }
            }
        }
    }

    func testEffectiveLineBreakMode() {
        let wrappingModes: [NSLineBreakMode] = [
            .byCharWrapping,
            .byWordWrapping,
        ]

        let nonWrappingModes: [NSLineBreakMode] = [
            .byClipping,
            .byTruncatingHead,
            .byTruncatingMiddle,
            .byTruncatingTail,
        ]

        let numberOfLines = [
            0,
            1,
            2,
        ]

        for mode in wrappingModes {
            for lineCount in numberOfLines {
                let effectiveMode = mode.textContainerMode(for: lineCount)
                if lineCount == 1 {
                    XCTAssertEqual(.byClipping, effectiveMode)
                } else {
                    XCTAssertEqual(mode, effectiveMode)
                }
            }
        }

        for mode in nonWrappingModes {
            for lineCount in numberOfLines {
                let effectiveMode = mode.textContainerMode(for: lineCount)
                if lineCount == 1 {
                    XCTAssertEqual(mode, effectiveMode)
                } else {
                    XCTAssertEqual(.byWordWrapping, effectiveMode)
                }
            }
        }
    }

}

struct TextContainerBox: Element {
    var model: AttributedLabel

    var content: ElementContent {
        model.content
    }

    func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        View.describe { config in
            config.apply { view in
                view.update(model: model, environment: context.environment)
            }
        }
    }

    class View: UIView {
        let textContainerView = UIView()
        let labelView = AttributedLabel.LabelView()
        var linkViews: [UIView] = []
        var model: AttributedLabel!

        override init(frame: CGRect) {
            super.init(frame: frame)
            textContainerView.backgroundColor = .red
            addSubview(textContainerView)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            labelView.frame = bounds

            guard let textStorage = labelView.makeTextStorage(),
                  let layoutManager = textStorage.layoutManagers.first,
                  let textContainer = layoutManager.textContainers.first
            else {
                return
            }

            textContainerView.frame = layoutManager.usedRect(for: textContainer)

            linkViews.forEach { $0.removeFromSuperview() }
            let attributedText = AttributedText(model.attributedText)

            for run in attributedText.runs.filter({ $0.link != nil }) {
                let view = UIView()
                view.backgroundColor = .yellow
                view.layer.borderColor = UIColor.cyan.cgColor
                view.layer.borderWidth = 1
                addSubview(view)
                let range = NSRange(run.range, in: attributedText.string)
                view.frame = layoutManager.boundingRect(forGlyphRange: range, in: textContainer)
            }
        }

        func update(model: AttributedLabel, environment: Environment) {
            self.model = model
            labelView.update(
                model: model,
                text: model.displayableAttributedText,
                environment: environment,
                isMeasuring: false
            )
        }
    }
}

extension NSAttributedString {

    func appending(string: String, font: UIFont, color: UIColor) -> NSAttributedString {
        let mutableResult = NSMutableAttributedString(attributedString: self)
        let stringToAppend = NSAttributedString(
            string: string,
            attributes: [
                NSAttributedString.Key.font: font,
                NSAttributedString.Key.foregroundColor: color,
            ]
        )
        mutableResult.append(stringToAppend)
        return NSAttributedString(attributedString: mutableResult)
    }

}
