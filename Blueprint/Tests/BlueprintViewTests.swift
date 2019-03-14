import XCTest
@testable import Blueprint

class BlueprintViewTests: XCTestCase {

    func test_displaysSimpleView() {

        let blueprintView = BlueprintView(element: SimpleViewElement(color: .red))

        XCTAssert(UIView.self == type(of: blueprintView.currentNativeViewControllers[0].node.view))
        XCTAssertEqual(blueprintView.currentNativeViewControllers[0].node.view.frame, blueprintView.bounds)
    }

    func test_updatesExistingViews() {
        let blueprintView = BlueprintView(element: SimpleViewElement(color: .green))

        let initialView = blueprintView.currentNativeViewControllers[0].node.view
        XCTAssertEqual(initialView.backgroundColor, UIColor.green)

        blueprintView.element = SimpleViewElement(color: .blue)

        XCTAssert(initialView === blueprintView.currentNativeViewControllers[0].node.view)
        XCTAssertEqual(initialView.backgroundColor, UIColor.blue)
    }



}


fileprivate struct SimpleViewElement: Element {

    var color: UIColor

    var content: ElementContent {
        return ElementContent(intrinsicSize: CGSize(width: 100, height: 100))
    }

    func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return UIView.describe { config in
            config[\.backgroundColor] = color
        }
    }

}
