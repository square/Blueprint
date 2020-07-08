import XCTest
import BlueprintUI
@testable import BlueprintUICommonControls


class LabelTests: XCTestCase {

    func test_snapshots() {

        compareSnapshot(identifier: "left") { label in
            label.alignment = .left
        }

        compareSnapshot(identifier: "center") { label in
            label.alignment = .center
        }

        compareSnapshot(identifier: "right") { label in
            label.alignment = .center
        }

        compareSnapshot(identifier: "justify") { label in
            label.alignment = .justified
        }

        compareSnapshot(identifier: "color") { label in
            label.color = .green
        }

        compareSnapshot(identifier: "font") { label in
            label.font = .boldSystemFont(ofSize: 32.0)
        }

        compareSnapshot(identifier: "two-lines") { label in
            label.numberOfLines = 2
        }

        compareSnapshot(identifier: "char-wrapping") { label in
            label.numberOfLines = 2
            label.lineBreakMode = .byCharWrapping
        }

        compareSnapshot(identifier: "clipping") { label in
            label.numberOfLines = 2
            label.lineBreakMode = .byClipping
        }

        compareSnapshot(identifier: "truncating-head") { label in
            label.numberOfLines = 2
            label.lineBreakMode = .byTruncatingHead
        }

        compareSnapshot(identifier: "truncating-middle") { label in
            label.numberOfLines = 2
            label.lineBreakMode = .byTruncatingMiddle
        }

        compareSnapshot(identifier: "truncating-tail") { label in
            label.numberOfLines = 2
            label.lineBreakMode = .byTruncatingTail
        }

        compareSnapshot(identifier: "word-wrapping") { label in
            label.numberOfLines = 2
            label.lineBreakMode = .byWordWrapping
        }
    }

    func test_customLineHeight() {
        let font = UIFont.systemFont(ofSize: UIFont.systemFontSize)
        let lineHeight = font.lineHeight * 2

        func variations(for alignment: Label.LineHeight.Alignment) -> Element {
            Row { row in
                row.verticalAlignment = .fill
                row.add(child: Rule(orientation: .vertical, color: .red))

                for numberOfLines in 0...2 {
                    let column = Column { column in
                        column.horizontalAlignment = .fill
                        column.add(child: Rule(orientation: .horizontal, color: .red))

                        for lineBreakMode in NSLineBreakMode.all {
                            let label = Label(text: "\(numberOfLines) \(lineBreakMode)") { label in
                                label.lineHeight = .custom(lineHeight: lineHeight, alignment: alignment)
                                label.numberOfLines = numberOfLines
                                label.lineBreakMode = lineBreakMode
                            }

                            let cell = label
                                .constrainedTo(width: .atMost(100), height: .absolute(lineHeight))

                            column.add(child: cell)
                            column.add(child: Rule(orientation: .horizontal, color: .red))
                        }
                    }
                    row.add(child: column)
                    row.add(child: Rule(orientation: .vertical, color: .red))
                }
            }
        }

        compareSnapshot(of: variations(for: .top), identifier: "top")

        compareSnapshot(of: variations(for: .center), identifier: "center")

        compareSnapshot(of: variations(for: .bottom), identifier: "bottom")
    }

    fileprivate func compareSnapshot(identifier: String? = nil, file: StaticString = #file, testName: String = #function, line: UInt = #line, configuration: (inout Label) -> Void) {
        var label = Label(text: "Hello, world. This is a long run of text that should wrap at some point. Someone should improve this test by adding a joke or something. Alright, it's been fun!")
        configuration(&label)
        compareSnapshot(of: label, size: CGSize(width: 300, height: 300), identifier: identifier, file: file, testName: testName, line: line)
    }

}

