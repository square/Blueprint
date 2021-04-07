import XCTest
@testable import BlueprintUI

class GridRowTests: XCTestCase {
    func test_defaults() {
        let gridRow = GridRow()
        XCTAssertTrue(gridRow.children.isEmpty)
        XCTAssertEqual(gridRow.verticalAlignment, .fill)
        XCTAssertEqual(gridRow.spacing, 0)
    }

    func test_measure_unconstrained() {
        do {
            // #1: Proportional child measurment
            //  proportions:      1,     2
            //  measured widths:  10,    25
            //  scales:           10,    12.5
            //  max scale:        12.5
            //  width:            (1 * 12.5) + (2 * 12.5) = 37.5
            //  height:           max(5, 10) = 10
            let gridRow = GridRow { row in
                row.add(child: .proportional(1, TestElement(size: CGSize(width: 10, height: 5))))
                row.add(child: .proportional(2, TestElement(size: CGSize(width: 25, height: 10))))
            }
            XCTAssertEqual(gridRow.content.measure(in: .unconstrained), CGSize(width: 37.5, height: 10))
        }

        do {
            // #2: Absolute and proportional child layout
            //  Same approach as #1, plus a 1x8 absolutely-sized child. Note the absolute sizing stretched this
            //  child to a width of 30.
            //   width:   37.5 + 30 = 67.5
            //   height:  max(5, 10, 50) = 50
            let gridRow = GridRow { row in
                row.add(child: .proportional(1, TestElement(size: CGSize(width: 10, height: 5))))
                row.add(child: .proportional(2, TestElement(size: CGSize(width: 25, height: 10))))
                row.add(child: .absolute(30, TestElement(size: CGSize(width: 1, height: 50))))
            }
            XCTAssertEqual(gridRow.content.measure(in: .unconstrained), CGSize(width: 67.5, height: 50))
        }

        do {
            // #3: Spacing
            //  Same approach as #1, plus a 5 point spacing between elements.
            //  width:   37.5 + 5.0 = 42.5
            //  height:  10
            let gridRow = GridRow { row in
                row.spacing = 5
                row.add(child: .proportional(1, TestElement(size: CGSize(width: 10, height: 5))))
                row.add(child: .proportional(2, TestElement(size: CGSize(width: 25, height: 10))))
            }
            XCTAssertEqual(gridRow.content.measure(in: .unconstrained), CGSize(width: 42.5, height: 10))
        }
    }

    func test_measure_constrained() {
        //  Proportional children size to fit the available width. The tallest child is used as the measured height.
        let gridRow = GridRow { row in
            row.add(child: .proportional(1, TestElement(size: CGSize(width: 10, height: 5))))
            row.add(child: .proportional(2, TestElement(size: CGSize(width: 25, height: 10))))
        }
        let constraint = SizeConstraint(width: .atMost(25), height: .atMost(100))
        XCTAssertEqual(gridRow.content.measure(in: constraint), CGSize(width: 25.0, height: 10))
    }

    func test_layout() {
        do {
            // #1: Proportional child layout
            //  proportions:      1,     2
            //  width:            30
            //  available width:  30
            //  widths:           10,    20
            let gridRow = GridRow { row in
                row.add(child: .proportional(1, TestElement(size: CGSize(width: 10, height: 5))))
                row.add(child: .proportional(2, TestElement(size: CGSize(width: 25, height: 10))))
            }

            let frames = gridRow.frames(in: CGSize(width: 30, height: 10))

            let expected = [
                CGRect(x: 0, y: 0, width: 10, height: 10),
                CGRect(x: 10, y: 0, width: 20, height: 10),
            ]

            XCTAssertEqual(frames, expected)
        }

        do {
            // #2: Absolute and proportional child layout
            //  proportions:      1,     2
            //  width:            40
            //  available width:  width - absolutely-sized -> 40 - 7  = 33
            //  widths:           11,    22,    7 (absolutely-sized)
            let gridRow = GridRow { row in
                row.add(child: .proportional(1, TestElement()))
                row.add(child: .proportional(2, TestElement()))
                row.add(child: .absolute(7, TestElement()))
            }

            let frames = gridRow.frames(in: CGSize(width: 40, height: 10))

            let expected = [
                CGRect(x: 0, y: 0, width: 11, height: 10),
                CGRect(x: 11, y: 0, width: 22, height: 10),
                CGRect(x: 33, y: 0, width: 7, height: 10),
            ]

            XCTAssertEqual(frames, expected)
        }

        do {
            // #3: Spacing
            //  proportions:      1,     2
            //  width:            40
            //  available width:  width - absolutely-sized - spacing -> 40 - 7 - 6  = 27
            //  widths:           9,    18,    7 (absolutely-sized)
            let gridRow = GridRow { row in
                row.spacing = 3
                row.add(child: .proportional(1, TestElement()))
                row.add(child: .proportional(2, TestElement()))
                row.add(child: .absolute(7, TestElement()))
            }

            let frames = gridRow.frames(in: CGSize(width: 40, height: 10))

            let expected = [
                CGRect(x: 0, y: 0, width: 9, height: 10),
                CGRect(x: 12, y: 0, width: 18, height: 10),
                CGRect(x: 33, y: 0, width: 7, height: 10),
            ]

            XCTAssertEqual(frames, expected)
        }
    }

    func test_layout_alignment() {
        let makeGridRow: (Row.RowAlignment) -> GridRow = { alignment in
            GridRow { row in
                row.verticalAlignment = alignment
                row.add(child: .proportional(1, TestElement(size: CGSize(width: 0, height: 5))))
                row.add(child: .proportional(1, TestElement(size: CGSize(width: 0, height: 10))))
            }
        }

        do {
            // #1: fill
            // Children grow to fill the height of 20.
            let gridRow = makeGridRow(.fill)

            let frames = gridRow.frames(in: CGSize(width: 40, height: 20))

            let expected = [
                CGRect(x: 0, y: 0, width: 20, height: 20),
                CGRect(x: 20, y: 0, width: 20, height: 20),
            ]

            XCTAssertEqual(frames, expected)
        }

        do {
            // #2: top
            let gridRow = makeGridRow(.top)

            let frames = gridRow.frames(in: CGSize(width: 40, height: 20))

            let expected = [
                CGRect(x: 0, y: 0, width: 20, height: 5),
                CGRect(x: 20, y: 0, width: 20, height: 10),
            ]

            XCTAssertEqual(frames, expected)
        }

        do {
            // #3: center
            // Children are positioned in the center (20 - h) / 2.
            let gridRow = makeGridRow(.center)

            let frames = gridRow.frames(in: CGSize(width: 40, height: 20))

            let expected = [
                CGRect(x: 0, y: 7.5, width: 20, height: 5),
                CGRect(x: 20, y: 5, width: 20, height: 10),
            ]

            XCTAssertEqual(frames, expected)
        }

        do {
            // #4: bottom
            // Children are positioned at the bottom (20 - h).
            let gridRow = makeGridRow(.bottom)

            let frames = gridRow.frames(in: CGSize(width: 40, height: 20))

            let expected = [
                CGRect(x: 0, y: 15, width: 20, height: 5),
                CGRect(x: 20, y: 10, width: 20, height: 10),
            ]

            XCTAssertEqual(frames, expected)
        }
    }

    func test_layout_edgeCases() {
        do {
            // #1: A `GridRow` with only absolute children justifies those childen to the start
            let gridRow = GridRow { row in
                row.add(child: .absolute(10, TestElement()))
                row.add(child: .absolute(15, TestElement()))
            }

            let frames = gridRow.frames(in: CGSize(width: 40, height: 20))

            let expected = [
                CGRect(x: 0, y: 0, width: 10, height: 20),
                CGRect(x: 10, y: 0, width: 15, height: 20),
            ]

            XCTAssertEqual(frames, expected)
        }

        do {
            // #2: A child with a proportion of 0 gets a width of 0
            let gridRow = GridRow { row in
                row.add(child: .proportional(1, TestElement()))
                row.add(child: .proportional(0, TestElement()))
            }

            let frames = gridRow.frames(in: CGSize(width: 40, height: 20))

            let expected = [
                CGRect(x: 0, y: 0, width: 40, height: 20),
                CGRect(x: 40, y: 0, width: 0, height: 20),
            ]

            XCTAssertEqual(frames, expected)
        }

        do {
            // #3: Absolute children can overlflow layout. Proportional children are sized to a width of 0 in these
            // cases.
            let gridRow = GridRow { row in
                row.add(child: .absolute(50, TestElement()))
                row.add(child: .proportional(1, TestElement()))
            }

            let frames = gridRow.frames(in: CGSize(width: 40, height: 20))

            let expected = [
                CGRect(x: 0, y: 0, width: 50, height: 20),
                CGRect(x: 50, y: 0, width: 0, height: 20),
            ]

            XCTAssertEqual(frames, expected)
        }
    }
}

private extension GridRow {
    func frames(in size: CGSize) -> [CGRect] {
        layout(frame: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            .children
            .map { $0.node.layoutAttributes.frame }
    }
}

private struct TestElement: Element {
    var size: CGSize

    init(size: CGSize = .zero) {
        self.size = size
    }

    var content: ElementContent {
        return ElementContent(intrinsicSize: size)
    }

    func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return nil
    }
}
