import XCTest
import BlueprintUI
@testable import BlueprintUICommonControls


class BoxTests: XCTestCase {

    func test_backgroundColor() {
        let box = Box(backgroundColor: .red)
        compareSnapshot(
            of: box,
            size: CGSize(width: 100, height: 100),
            identifier: "red")

        compareSnapshot(
            of: Box(backgroundColor: .clear),
            size: CGSize(width: 100, height: 100),
            identifier: "clear")
    }

    func test_cornerStyle() {
        do {
            var box = Box()
            box.backgroundColor = .blue
            box.cornerStyle = .capsule
            
            compareSnapshot(
                of: box,
                size: CGSize(width: 200, height: 100),
                identifier: "wideCapsule"
            )

            compareSnapshot(
                of: box,
                size: CGSize(width: 100, height: 200),
                identifier: "longCapsule"
            )
        }

        do {
            var box = Box()
            box.backgroundColor = .blue
            box.cornerStyle = .rounded(radius: 10.0)
            
            compareSnapshot(
                of: box,
                size: CGSize(width: 100, height: 100),
                identifier: "roundedAllCorners"
            )
        }
        
        do {
            var box = Box()
            box.backgroundColor = .blue
            box.cornerStyle = .rounded(radius: 10.0, corners: [.topLeft, .topRight])
            
            compareSnapshot(
                of: box,
                size: CGSize(width: 100, height: 100),
                identifier: "roundTopCorners"
            )
        }
        
        do {
            var box = Box()
            box.backgroundColor = .blue
            box.cornerStyle = .rounded(radius: 10.0, corners: [.bottomLeft, .bottomRight])
            
            compareSnapshot(
                of: box,
                size: CGSize(width: 100, height: 100),
                identifier: "roundBottomCorners"
            )
        }
    }

    func test_shadow() {
        var element = InsettingElement()
        element.box.backgroundColor = UIColor.green
        element.box.cornerStyle = .rounded(radius: 10.0)
        element.box.shadowStyle = .simple(radius: 8.0, opacity: 1.0, offset: .zero, color: .magenta)

        compareSnapshot(
            of: element,
            size: CGSize(width: 100, height: 100))
    }

    func test_borders() {

        do {
            var box = Box()
            box.backgroundColor = .blue
            box.borderStyle = .solid(color: .orange, width: 1.0)
            compareSnapshot(
                of: box,
                size: CGSize(width: 100, height: 100),
                identifier: "square")
        }

        do {
            var box = Box()
            box.backgroundColor = .blue
            box.cornerStyle = .rounded(radius: 10.0)
            box.borderStyle = .solid(color: .orange, width: 1.0)
            compareSnapshot(
                of: box,
                size: CGSize(width: 100, height: 100),
                identifier: "rounded")
        }
    }

    func test_displaysContent() {
        var element = InsettingElement()
        element.box.wrappedElement = Label(text: "Hello, world")
        compareSnapshot(
            of: element,
            size: CGSize(width: 100, height: 100))
    }

    func test_largeCornerRadius() {
        var element = InsettingElement()
        element.box.backgroundColor = .blue
        element.box.cornerStyle = .rounded(radius: 100)
        element.box.shadowStyle = .simple(radius: 2, opacity: 1, offset: .zero, color: .red)
        compareSnapshot(
            of: element,
            size: CGSize(width: 120, height: 100))
    }
    
}


class UIRectCornerTests : XCTestCase {
    
    func test_toCACornerMask() {
        
        /// `CACornerMask` is based on the macOS coordinate system, which starts in the top left, not the bottom left like iOS.
        
        XCTAssertEqual(UIRectCorner.topLeft.toCACornerMask, CACornerMask.layerMinXMinYCorner)
        XCTAssertEqual(UIRectCorner.topRight.toCACornerMask, CACornerMask.layerMaxXMinYCorner)
        XCTAssertEqual(UIRectCorner.bottomRight.toCACornerMask, CACornerMask.layerMaxXMaxYCorner)
        XCTAssertEqual(UIRectCorner.bottomLeft.toCACornerMask, CACornerMask.layerMinXMaxYCorner)
    }
}



private struct InsettingElement: Element {

    var box: Box = Box()

    func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return nil
    }

    var content: ElementContent {
        return ElementContent(child: box, layout: Layout())
    }

    private struct Layout: SingleChildLayout {
        func measure(in constraint: SizeConstraint, child: Measurable) -> CGSize {
            return .zero
        }
        func layout(size: CGSize, child: Measurable) -> LayoutAttributes {
            return LayoutAttributes(frame: CGRect(origin: .zero, size: size).insetBy(dx: 20, dy: 20))
        }
    }

}
