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

    func test_accessibilityConfiguration() {
        let string = NSAttributedString(string: "Hello, World!")

        let label = AttributedLabel(attributedText: string) { label in
            label.isAccessibilityElement = true
            label.accessibilityHint = "Hint"
            label.accessibilityValue = "Value"
            label.accessibilityIdentifier = "Identifier"
        }

        let view = BlueprintView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))

        label.accessBackingView(in: view) { view in
            XCTAssertTrue(view.isAccessibilityElement)
            XCTAssertEqual(view.accessibilityHint, "Hint")
            XCTAssertEqual(view.accessibilityValue, "Value")
            XCTAssertEqual(view.accessibilityIdentifier, "Identifier")
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

    func test_linkTapDetection() {

        func perform(
            identifier: String,
            with string: String,
            size: CGSize,
            style: (NSMutableParagraphStyle) -> Void,
            file: StaticString = #file,
            testName: String = #function,
            line: UInt = #line
        ) {
            compareSnapshot(
                of: LabelTapDetectionGrid(
                    wrapping: AttributedLabel(
                        attributedText: NSAttributedString(
                            string: string,
                            attributes: [.paragraphStyle: NSParagraphStyle.style { style($0) }]
                        )
                    ) {
                        $0.linkDetectionTypes = [.link]
                    }
                ),
                size: size,
                identifier: identifier,
                file: file,
                testName: testName,
                line: line
            )
        }

        let short = "Short text https://squareup.com"

        perform(
            identifier: "short left",
            with: short,
            size: CGSize(width: 500, height: 50),
            style: {
                $0.alignment = .left
            }
        )

        perform(
            identifier: "short centered",
            with: short,
            size: CGSize(width: 500, height: 50),
            style: {
                $0.alignment = .center
            }
        )

        perform(
            identifier: "short right",
            with: short,
            size: CGSize(width: 500, height: 50),
            style: {
                $0.alignment = .right
            }
        )

        let long = "Here’s to the crazy ones, the misfits at https://block.xyz, the rebels, the troublemakers, the round pegs in the https://squareup.com holes… the ones who see things differently"

        perform(
            identifier: "long left",
            with: long,
            size: CGSize(width: 300, height: 200),
            style: {
                $0.alignment = .left
            }
        )

        perform(
            identifier: "long centered",
            with: long,
            size: CGSize(width: 300, height: 200),
            style: {
                $0.alignment = .center
            }
        )

        perform(
            identifier: "long right",
            with: long,
            size: CGSize(width: 300, height: 200),
            style: {
                $0.alignment = .right
            }
        )
    }

    func test_linkAttribute() {
        let string = NSAttributedString(string: "Some text", attributes: [.link: URL(string: "https://block.xyz")!])
        let element = AttributedLabel(attributedText: string) {
            $0.linkAttributes = [.foregroundColor: UIColor.red, .backgroundColor: UIColor.black]
        }

        compareSnapshot(of: element)
    }

    func test_multilineAccessibility() {
        let labelview = AttributedLabel.LabelView()

        for (text, expected) in [
            ("Test Test", "Test Test"),
            ("Test\nTest", "Test Test"),
            ("Test\n\nTest", "Test Test"),
            ("\n\n\n\nTest\n\n\nTest\n\n\n", "Test Test"),
        ] {
            let result = labelview.accessibilityLabel(with: [], in: text, linkAccessibilityLabel: nil)
            XCTAssertEqual(expected, result)
        }
    }

    func test_attributedValue() throws {
        let view = BlueprintView()

        view.element = AttributedLabel(attributedText: NSAttributedString(string: "Some string with stuff")) {
            $0.accessibilityValue = "A value"
        }

        view.layoutIfNeeded()

        let labelView = try XCTUnwrap(view.firstSubview(ofType: AttributedLabel.LabelView.self))

        XCTAssertEqual(labelView.accessibilityValue, "A value")
    }

    func test_linkAccessibility() {
        let labelview = AttributedLabel.LabelView()

        do {
            // Test that link insertion happy path works
            let string = NSString("Foo Bar Baz")
            let url = URL(string: "https://block.xyz")!
            for (word, result) in [
                ("Foo", "Foo[Link] Bar Baz"),
                ("Bar", "Foo Bar[Link] Baz"),
                ("Baz", "Foo Bar Baz[Link]"),
            ] {
                let range = string.range(of: word)
                let link = AttributedLabel.Link(url: url, range: range)
                let accessibilityLabel = labelview.accessibilityLabel(
                    with: [link],
                    in: string as String,
                    linkAccessibilityLabel: "Link"
                )
                XCTAssertEqual(accessibilityLabel, result)
            }
        }

        do {
            // Test every position
            let numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
            let string = numbers.map { String($0) }.joined() as NSString
            let url = URL(string: "https://block.xyz")!
            for number in numbers {
                let range = NSMakeRange(max(0, number - 2), 1)
                let link = AttributedLabel.Link(url: url, range: range)
                let accessibilityLabel = labelview.accessibilityLabel(
                    with: [link],
                    in: string as String,
                    linkAccessibilityLabel: "."
                ) as NSString
                XCTAssertNotEqual(accessibilityLabel, string)
            }
        }

        do {
            // Test stupid ranges don't crash
            let string = "Foo Bar Baz"
            let url = URL(string: "https://block.xyz")!
            let badRanges = [
                NSMakeRange(0, 0),
                NSMakeRange(-1, 0),
                NSMakeRange(0, -1),
                NSMakeRange(0, 100),
                NSMakeRange(100, 0),
                NSMakeRange(100, -100),
            ]
            for range in badRanges {
                let link = AttributedLabel.Link(url: url, range: range)
                let accessibilityLabel = labelview.accessibilityLabel(
                    with: [link],
                    in: string as String,
                    linkAccessibilityLabel: "."
                )
                XCTAssertEqual(accessibilityLabel, string)
            }
        }

        do {
            // Test with emoji
            let string = "🇺🇸🇨🇦🇯🇵🇫🇷"
            let url = URL(string: "https://block.xyz")!
            let range = NSRange(string.range(of: "🇨🇦")!, in: string)
            let link = AttributedLabel.Link(url: url, range: range)

            let accessibilityLabel = labelview.accessibilityLabel(
                with: [link],
                in: string as String,
                linkAccessibilityLabel: "."
            )
            XCTAssertEqual(accessibilityLabel, "🇺🇸🇨🇦[.]🇯🇵🇫🇷")
        }
    }


    func test_linkAccessibility_Rotors() {
        let labelView = AttributedLabel.LabelView()
        let text: NSString = "The Fellowship of the ring was established at the Council of Elrond and consisted of Gandalf, Sam, Frodo, Aragorn, Gimli, Pippin, Boromir, Legolas, and Merry."

        let url = URL(string: "https://one.ring")!

        let links = ["Frodo", "Merry", "Sam", "Pippin"].map {
            AttributedLabel.Link(url: url, range: text.range(of: $0))
        }

        let rotor = labelView.accessibilityRotor(for: links, in: NSAttributedString(string: text as String))
        XCTAssertNotNil(rotor)

        // links should be sorted by their position in the main string.
        let sortedHobbits = rotor.dumpItems().map { $0.accessibilityLabel }
        XCTAssertEqual(sortedHobbits, ["Sam", "Frodo", "Pippin", "Merry"])
    }



    func test_linkAccessibility_Rotors_update() {
        let string = "The Fellowship of the ring was established at the Council of Elrond and consisted of Gandalf, Sam, Frodo, Aragorn, Gimli, Pippin, Boromir, Legolas, and Merry."
        var attributedText = AttributedText(string)

        for hobbit in ["Frodo", "Merry", "Sam", "Pippin"] {
            let range = attributedText.range(of: hobbit)!
            attributedText[range].link = URL(string: "https://one.ring")!
        }

        var label = AttributedLabel(attributedText: attributedText.attributedString)
        let labelView = AttributedLabel.LabelView()
        labelView.update(model: label, text: label.attributedText, environment: .empty, isMeasuring: false)

        let rotor = labelView.accessibilityCustomRotors!.first!
        XCTAssertNotNil(rotor)

        // links should be sorted by their position in the main string.
        let sortedHobbits = rotor.dumpItems().map { $0.accessibilityLabel }
        XCTAssertEqual(sortedHobbits, ["Sam", "Frodo", "Pippin", "Merry"])

        let removedLinks = AttributedText(string)
        label.attributedText = removedLinks.attributedString
        labelView.update(model: label, text: label.attributedText, environment: .empty, isMeasuring: false)
        XCTAssertTrue(labelView.accessibilityCustomRotors!.isEmpty)

        var updatedText = AttributedText(string)
        for name in ["Aragorn", "Gandalf", "Gimli", "Legolas", "Boromir"] {
            let range = updatedText.range(of: name)!
            updatedText[range].link = URL(string: "https://one.ring")!
        }
        label.attributedText = updatedText.attributedString
        labelView.update(model: label, text: label.attributedText, environment: .empty, isMeasuring: false)

        let updatedRotor = labelView.accessibilityCustomRotors!.first!
        XCTAssertNotNil(updatedRotor)

        let notHobbits = updatedRotor.dumpItems().map { $0.accessibilityLabel }
        XCTAssertEqual(notHobbits, ["Gandalf", "Aragorn", "Gimli", "Boromir", "Legolas"])
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

extension UIAccessibilityCustomRotor {
    fileprivate func dumpItems() -> [NSObject] {
        var results = [UIAccessibilityCustomRotorItemResult]()
        let predicate = UIAccessibilityCustomRotorSearchPredicate()
        predicate.searchDirection = .next
        let first = itemSearchBlock(predicate)
        XCTAssertNotNil(first)
        results.append(first!)
        predicate.currentItem = first!
        while let last = results.last,
              let next = itemSearchBlock(predicate),
              last.targetElement as! NSObject != next.targetElement as! NSObject
        {
            results.append(next)
            predicate.currentItem = next
        }
        return results.compactMap { $0.targetElement as? NSObject }
    }
}

fileprivate struct LabelTapDetectionGrid: Element {

    var wrapping: Element

    var content: ElementContent {
        ElementContent(child: wrapping)
    }

    func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        View.describe { _ in }
    }

    private final class View: UIView {

        private let overlay: BlueprintView

        override init(frame: CGRect) {

            overlay = BlueprintView()
            overlay.backgroundColor = .clear

            super.init(frame: frame)

            overlay.frame = bounds

            addSubview(overlay)
        }

        required init?(coder: NSCoder) { fatalError() }

        override func layoutSubviews() {

            super.layoutSubviews()

            let label = firstSubview(ofType: AttributedLabel.LabelView.self)

            overlay.frame = bounds

            guard let label else { return }

            let bounds = bounds

            let stride = 6

            overlay.element = LayoutWriter { context, builder in

                for x in 0...Int(bounds.width / CGFloat(stride)) {
                    for y in 0...Int(bounds.height / CGFloat(stride)) {

                        let x = CGFloat(x * stride)
                        let y = CGFloat(y * stride)

                        let point = CGPoint(x: CGFloat(x), y: CGFloat(y))
                        let labelPoint = label.convert(point, from: self)

                        let links = label.links(at: labelPoint)

                        if links.isEmpty == false {
                            builder.add(
                                with: CGRect(x: x - 2.0, y: y - 2.0, width: 4, height: 4),
                                child: Box(backgroundColor: .red.withAlphaComponent(0.4), cornerStyle: .capsule)
                            )
                        }
                    }
                }
            }

            overlay.layoutIfNeeded()
        }
    }
}

extension UIView {

    fileprivate func firstSubview<ViewType: UIView>(ofType type: ViewType.Type) -> ViewType? {

        for subview in subviews {
            if subview.isKind(of: type) {
                return (subview as! ViewType)
            }

            return subview.firstSubview(ofType: type)
        }

        return nil
    }

}

extension NSParagraphStyle {

    static func style(_ configure: (NSMutableParagraphStyle) -> Void) -> NSParagraphStyle {

        let style = NSMutableParagraphStyle()

        configure(style)

        return style.copy() as! NSParagraphStyle
    }
}

fileprivate struct TextContainerBox: Element {
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
