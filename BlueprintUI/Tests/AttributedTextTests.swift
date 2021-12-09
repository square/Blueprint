import XCTest
@testable import BlueprintUI

class AttributedTextTests: XCTestCase {

    func testApplyingAttributes() {
        let font = UIFont.systemFont(ofSize: 30)
        let color = UIColor.green

        var text = AttributedText("Hello world")
        text.font = font
        text.color = color

        XCTAssertEqual(text[text.range(of: "Hello world")!].font, font)
        XCTAssertEqual(text[text.range(of: "Hello world")!].color, color)

        XCTAssertEqual(text[text.range(of: "Hello")!].font, font, "Attributes that span the range should be returned")
        XCTAssertEqual(text[text.range(of: "Hello")!].color, color, "Attributes that span the range should be returned")

        text.attributedString.enumerateAttributes(
            in: text.attributedString.entireRange,
            options: []
        ) { attributes, range, _ in
            XCTAssertEqual(attributes[.font] as? UIFont, font)
            XCTAssertEqual(attributes[.foregroundColor] as? UIColor, color)
            XCTAssertEqual(range, text.attributedString.entireRange)
        }
    }

    func testApplyingPartialAttributes() {
        let font = UIFont.systemFont(ofSize: 30)
        let green = UIColor.green
        let blue = UIColor.blue

        var text = AttributedText("Hello world")

        let hello = text.range(of: "Hello")!
        let world = text.range(of: "world")!
        let loWo = text.range(of: "lo wo")!
        let rld = text.range(of: "rld")!

        text[hello].font = font
        text[world].color = green
        text[loWo].color = blue

        XCTAssertEqual(text[hello].font, font, "The font should be returned when it applies to the whole range")
        XCTAssertEqual(
            text[text.range(of: "ell")!].font,
            font,
            "The font should be returned when it applies to the whole range"
        )
        XCTAssertNil(
            text[text.range(of: "Hello wo")!].font,
            "The font should not be returned if it applies to part of the range"
        )
        XCTAssertNil(text[loWo].font, "The font should not be returned if it applies to part of the range")

        XCTAssertEqual(text[loWo].color, blue, "The color should be returned if it applies to the whole range")
        XCTAssertEqual(text[rld].color, green, "The color should be returned if it applies to the whole range")
        XCTAssertNil(text[world].color, "The color should not be returned if it applies to part of the range")

        text.attributedString.enumerateAttribute(
            .font,
            in: text.attributedString.entireRange,
            options: []
        ) { attribute, range, _ in
            if range == text.nsRange(of: "Hello") {
                XCTAssertEqual(attribute as? UIFont, font)
            } else if range == text.nsRange(of: " world") {
                XCTAssertNil(attribute)
            } else {
                XCTFail("Unexpected range for font attribute")
            }
        }

        text.attributedString.enumerateAttribute(
            .foregroundColor,
            in: text.attributedString.entireRange,
            options: []
        ) { attribute, range, _ in
            let attribute = attribute as? UIColor

            if range == text.nsRange(of: "Hel") {
                XCTAssertNil(attribute)
            } else if range == text.nsRange(of: "lo wo") {
                XCTAssertEqual(attribute, blue)
            } else if range == text.nsRange(of: "rld") {
                XCTAssertEqual(attribute, green)
            } else {
                XCTFail("Unexpected range for color attribute")
            }
        }
    }

    func testConcatenation() {
        var left = AttributedText("left")
        left.color = .blue
        left[left.range(of: "le")!].tracking = 20

        var right = AttributedText("right")
        right.tracking = 10
        right[right.range(of: "ig")!].color = .green

        let concat = left + right
        XCTAssertEqual(concat[concat.range(of: "left")!].color, .blue)
        XCTAssertEqual(concat[concat.range(of: "le")!].tracking, 20)
        XCTAssertEqual(concat[concat.range(of: "ig")!].color, .green)
        XCTAssertEqual(concat[concat.range(of: "right")!].tracking, 10)
    }

    func testValueSemantics() {
        let text = AttributedText("Hello world")
        var copy = text
        copy.font = .systemFont(ofSize: 20)
        XCTAssertNil(text.font)
    }

    func testEmoji() {
        var text = AttributedText("some emoji: 😵‍💫👨‍👩‍👧‍👦🏃🏽 and some hiragana:  あいうえお and some katakana: アイウエオカキクケコ")
        text.color = .blue

        let partialEmoji = text.range(of: "😵")!
        text[partialEmoji].color = .brown

        let family = text.range(of: "👨‍👩‍👧‍👦")!
        text[family].color = .magenta

        let someHiragana = text.range(of: "いうえ")!
        text[someHiragana].color = .green

        let someKatakana = text.range(of: "ウエオカキク")!
        text[someKatakana].color = .red

        XCTAssertEqual(text["😵‍💫"].color, nil, "This emoji spans two colors due to changing the color of 😵")
        XCTAssertEqual(text["🏃🏽"].color, .blue)
        XCTAssertEqual(text["あ"].color, .blue)
        XCTAssertEqual(text["アイ"].color, .blue)

        XCTAssertEqual(text[partialEmoji].color, .brown)
        XCTAssertEqual(text[family].color, .magenta)
        XCTAssertEqual(text[someHiragana].color, .green)
        XCTAssertEqual(text[someKatakana].color, .red)
    }

    func testRemovingAttributes() {
        var text = AttributedText("Hello")
        text.font = .systemFont(ofSize: 10)
        text.color = .blue

        text.font = nil
        text["H"].color = nil

        XCTAssertNil(text.font)
        XCTAssertNil(text["H"].color)
        XCTAssertEqual(text["ello"].color, .blue)
    }
}

extension AttributedText {
    fileprivate subscript(_ string: String) -> TextAttributeContainer {
        get { self[range(of: string)!] }
        set { self[range(of: string)!] = newValue }
    }

    fileprivate func nsRange(of string: String) -> NSRange {
        NSRange(range(of: string)!, in: self.string)
    }
}

extension NSAttributedString {
    fileprivate var entireRange: NSRange {
        NSRange(location: 0, length: length)
    }
}
