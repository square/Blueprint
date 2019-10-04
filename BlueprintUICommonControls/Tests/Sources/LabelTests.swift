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

    fileprivate func compareSnapshot(identifier: String? = nil, file: StaticString = #file, testName: String = #function, line: UInt = #line, configuration: (inout Label) -> Void) {
        var label = Label(text: "Hello, world. This is a long run of text that should wrap at some point. Someone should improve this test by adding a joke or something. Alright, it's been fun!")
        label.roundingScale = 1
        configuration(&label)
        compareSnapshot(of: label, size: CGSize(width: 300, height: 300), identifier: identifier, file: file, testName: testName, line: line)
    }

}

