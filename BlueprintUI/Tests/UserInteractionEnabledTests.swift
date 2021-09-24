import XCTest
@testable import BlueprintUI

final class UserInteractionEnabledTests: XCTestCase {
    func test() throws {
        do {
            let enabled = UserInteractionEnabled(true, wrapping: TestElement())
            let layout = enabled.layout(frame: CGRect(origin: .zero, size: .init(width: 10, height: 10)))
            if let child = layout.findLayout(of: TestElement.self) {
                XCTAssertEqual(
                    child.layoutAttributes.isUserInteractionEnabled,
                    true
                )
            } else {
                XCTFail("TestElement should be a child element")
            }
        }

        do {
            let disabled = UserInteractionEnabled(false, wrapping: TestElement())
            let layout = disabled.layout(frame: CGRect(origin: .zero, size: .init(width: 10, height: 10)))
            if let child = layout.findLayout(of: TestElement.self) {
                XCTAssertEqual(
                    child.layoutAttributes.isUserInteractionEnabled,
                    false
                )
            } else {
                XCTFail("TestElement should be a child element")
            }
        }
    }

    func test_convenience() throws {
        do {
            let enabled = TestElement().userInteractionEnabled(true)
            let layout = enabled.layout(frame: CGRect(origin: .zero, size: .init(width: 10, height: 10)))
            if let child = layout.findLayout(of: TestElement.self) {
                XCTAssertEqual(
                    child.layoutAttributes.isUserInteractionEnabled,
                    true
                )
            } else {
                XCTFail("TestElement should be a child element")
            }
        }

        do {
            let disabled = TestElement().userInteractionEnabled(false)
            let layout = disabled.layout(frame: CGRect(origin: .zero, size: .init(width: 10, height: 10)))
            if let child = layout.findLayout(of: TestElement.self) {
                XCTAssertEqual(
                    child.layoutAttributes.isUserInteractionEnabled,
                    false
                )
            } else {
                XCTFail("TestElement should be a child element")
            }
        }
    }

    /// A view-backed box to generate a native view node
    struct TestElement: Element {
        var content: ElementContent {
            ElementContent(intrinsicSize: .init(width: 10, height: 10))
        }

        func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
            UIView.describe { _ in }
        }
    }
}
