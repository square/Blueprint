import XCTest
@testable @_spi(CacheManagement) import BlueprintUI

class CacheClearerTests: XCTestCase {

    func test_clearStaticCaches() {

        struct TestElement: UIViewElement {
            func makeUIView() -> UIView {
                UIView()
            }

            func updateUIView(_ view: UIView, with context: BlueprintUI.UIViewElementContext) {}
        }

        let _ = UIViewElementMeasurer.shared.measure(
            element: TestElement(),
            constraint: .unconstrained,
            environment: .empty
        )

        XCTAssertEqual(UIViewElementMeasurer.shared.cachedViewCount, 1)

        CacheClearer.clearStaticCaches()

        XCTAssertEqual(UIViewElementMeasurer.shared.cachedViewCount, 0)
    }
}

