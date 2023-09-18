import XCTest
@testable import BlueprintUI

final class TintAdjustmentModeTests: XCTestCase {
    func test() throws {
        do {
            let wrapped = TintAdjustmentMode(.normal, wrapping: TestElement())
            let layout = wrapped.layout(frame: CGRect(origin: .zero, size: .init(width: 10, height: 10)))
            if let child = layout.findLayout(of: TestElement.self) {
                XCTAssertEqual(
                    child.layoutAttributes.tintAdjustmentMode,
                    .normal
                )
            } else {
                XCTFail("TestElement should be a child element")
            }
        }
    }

    func test_convenience() throws {
        do {
            let wrapped = TestElement().tintAdjustmentMode(.normal)
            let layout = wrapped.layout(frame: CGRect(origin: .zero, size: .init(width: 10, height: 10)))
            if let child = layout.findLayout(of: TestElement.self) {
                XCTAssertEqual(
                    child.layoutAttributes.tintAdjustmentMode,
                    .normal
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
