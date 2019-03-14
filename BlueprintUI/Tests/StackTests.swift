import XCTest
@testable import BlueprintUI

class StackTests: XCTestCase {

    func test_defaults() {
        let column = Column()
        XCTAssertEqual(column.minimumVerticalSpacing, 0.0)
        XCTAssertEqual(column.horizontalAlignment, .leading)
        XCTAssertEqual(column.verticalOverflow, .condenseProportionally)
        XCTAssertEqual(column.verticalUnderflow, .spaceEvenly)
    }

    func test_vertical() {
        var column = Column()
        column.add(child: TestElement())
        column.add(child: TestElement())

        XCTAssertEqual(column.content.measure(in: .unconstrained).width, 100)
        XCTAssertEqual(column.content.measure(in: .unconstrained).height, 200)

        let children = column
            .layout(frame: CGRect(x: 0, y: 0, width: 100, height: 200))
            .children
            .map { $0.node }

        XCTAssertEqual(children.count, 2)

        XCTAssertEqual(children[0].layoutAttributes.frame, CGRect(x: 0, y: 0, width: 100, height: 100))
        XCTAssertEqual(children[1].layoutAttributes.frame, CGRect(x: 0, y: 100, width: 100, height: 100))
    }

    func test_horizontal() {
        var row = Row()
        row.add(child: TestElement())
        row.add(child: TestElement())

        XCTAssertEqual(row.content.measure(in: .unconstrained).width, 200)
        XCTAssertEqual(row.content.measure(in: .unconstrained).height, 100)

        let children = row
            .layout(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
            .children
            .map { $0.node }

        XCTAssertEqual(children.count, 2)

        XCTAssertEqual(children[0].layoutAttributes.frame, CGRect(x: 0, y: 0, width: 100, height: 100))
        XCTAssertEqual(children[1].layoutAttributes.frame, CGRect(x: 100, y: 0, width: 100, height: 100))
    }

    func test_minimumSpacing() {
        var row = Row()
        row.add(child: TestElement())
        row.add(child: TestElement())
        row.minimumHorizontalSpacing = 10.0

        XCTAssertEqual(row.content.measure(in: .unconstrained).width, 210)
        XCTAssertEqual(row.content.measure(in: .unconstrained).height, 100)

        let children = row
            .layout(frame: CGRect(x: 0, y: 0, width: 210, height: 100))
            .children
            .map { $0.node }

        XCTAssertEqual(children[0].layoutAttributes.frame, CGRect(x: 0, y: 0, width: 100, height: 100))
        XCTAssertEqual(children[1].layoutAttributes.frame, CGRect(x: 110, y: 0, width: 100, height: 100))
    }

    func test_alignment() {


        func test(
            alignment: StackLayout.Alignment,
            layoutCrossSize: CGFloat,
            elementCrossSize: CGFloat,
            expectedOrigin: CGFloat,
            expectedSize: CGFloat,
            file: StaticString = #file,
            line: UInt = #line) {

            do {
                var column = Column()
                column.add(child: TestElement(size: CGSize(width: elementCrossSize, height: 100)))
                column.horizontalAlignment = alignment

                XCTAssertEqual(
                    column
                        .layout(frame: CGRect(x: 0, y: 0, width: layoutCrossSize, height: 100))
                        .children[0]
                        .node
                        .layoutAttributes
                        .frame,
                    CGRect(x: expectedOrigin, y: 0.0, width: expectedSize, height: 100),
                    "Vertical",
                    file: file,
                    line: line
                )
            }

            do {
                var row = Row()
                row.add(child: TestElement(size: CGSize(width: 100, height: elementCrossSize)))
                row.verticalAlignment = alignment

                XCTAssertEqual(
                    row
                        .layout(frame: CGRect(x: 0, y: 0, width: 100, height: layoutCrossSize))
                        .children[0]
                        .node
                        .layoutAttributes
                        .frame,
                    CGRect(x: 0.0, y: expectedOrigin, width: 100, height: expectedSize),
                    "Horizontal",
                    file: file,
                    line: line
                )
            }



        }

        test(alignment: .leading, layoutCrossSize: 200, elementCrossSize: 100, expectedOrigin: 0, expectedSize: 100)
        test(alignment: .trailing, layoutCrossSize: 200, elementCrossSize: 100, expectedOrigin: 100, expectedSize: 100)
        test(alignment: .fill, layoutCrossSize: 200, elementCrossSize: 100, expectedOrigin: 0, expectedSize: 200)
        test(alignment: .center, layoutCrossSize: 200, elementCrossSize: 100, expectedOrigin: 50, expectedSize: 100)

    }

    func test_underflow() {

        func test(
            underflow: StackLayout.UnderflowDistribution,
            layoutLength: CGFloat,
            items: [(measuredLength: CGFloat, growPriority: CGFloat)],
            expectedRanges: [ClosedRange<CGFloat>],
            file: StaticString = #file,
            line: UInt = #line) {

            do {
                var row = Row()
                for item in items {
                    row.add(
                        growPriority: item.growPriority,
                        shrinkPriority: 1.0,
                        child: TestElement(size: CGSize(width: item.measuredLength, height: 100)))
                }
                row.horizontalUnderflow = underflow

                let childRanges = row
                    .layout(frame: CGRect(x: 0, y: 0, width: layoutLength, height: 100))
                    .children
                    .map {
                        ClosedRange(uncheckedBounds: ($0.node.layoutAttributes.frame.minX, $0.node.layoutAttributes.frame.maxX))
                    }

                XCTAssertEqual(childRanges, expectedRanges, "Horizontal", file: file, line: line)
            }

            do {
                var column = Column()
                for item in items {
                    column.add(
                        growPriority: item.growPriority,
                        shrinkPriority: 1.0,
                        child: TestElement(size: CGSize(width: 100, height: item.measuredLength)))
                }
                column.verticalUnderflow = underflow

                let childRanges = column
                    .layout(frame: CGRect(x: 0, y: 0, width: 100, height: layoutLength))
                    .children
                    .map {
                        ClosedRange(uncheckedBounds: ($0.node.layoutAttributes.frame.minY, $0.node.layoutAttributes.frame.maxY))
                    }

                XCTAssertEqual(childRanges, expectedRanges, "Vertical", file: file, line: line)
            }

        }


        // Test single child for different underflow distributions, including different grow priorities.
        do {
            test(
                underflow: .spaceEvenly,
                layoutLength: 200,
                items: [
                    (measuredLength: 100, growPriority: 1.0)
                ],
                expectedRanges: [
                    0...100
                ])

            test(
                underflow: .spaceEvenly,
                layoutLength: 200,
                items: [
                    (measuredLength: 100, growPriority: 0.0)
                ],
                expectedRanges: [
                    0...100
                ])

            test(
                underflow: .growProportionally,
                layoutLength: 200,
                items: [
                    (measuredLength: 100, growPriority: 1.0)
                ],
                expectedRanges: [
                    0...200
                ])

            test(
                underflow: .growProportionally,
                layoutLength: 200,
                items: [
                    (measuredLength: 100, growPriority: 0.0)
                ],
                expectedRanges: [
                    0...100
                ])

            test(
                underflow: .growUniformly,
                layoutLength: 200,
                items: [
                    (measuredLength: 100, growPriority: 1.0)
                ],
                expectedRanges: [
                    0...200
                ])

            test(
                underflow: .growUniformly,
                layoutLength: 200,
                items: [
                    (measuredLength: 100, growPriority: 0.0)
                ],
                expectedRanges: [
                    0...100
                ])
        }

        // Test with default grow priorities
        do {

            test(
                underflow: .spaceEvenly,
                layoutLength: 400, items: [
                    (measuredLength: 100, growPriority: 1.0),
                    (measuredLength: 100, growPriority: 1.0)
                ], expectedRanges: [
                    0...100,
                    300...400
                ])

            test(
                underflow: .growUniformly,
                layoutLength: 400, items: [
                    (measuredLength: 200, growPriority: 1.0),
                    (measuredLength: 100, growPriority: 1.0)
                ], expectedRanges: [
                    0...250,
                    250...400
                ])

            test(
                underflow: .growProportionally,
                layoutLength: 600, items: [
                    (measuredLength: 200, growPriority: 1.0),
                    (measuredLength: 100, growPriority: 1.0)
                ], expectedRanges: [
                    0...400,
                    400...600
                ])

        }

        // Test with custom grow priorities
        do {

            test(
                underflow: .spaceEvenly,
                layoutLength: 400,
                items: [
                    (measuredLength: 100, growPriority: 3.0),
                    (measuredLength: 100, growPriority: 1.0)
                ], expectedRanges: [
                    0...100,
                    300...400
                ])

            test(
                underflow: .growUniformly,
                layoutLength: 600,
                items: [
                    (measuredLength: 100, growPriority: 3.0),
                    (measuredLength: 100, growPriority: 1.0)
                ], expectedRanges: [
                    0...400,
                    400...600
                ])

            test(
                underflow: .growProportionally,
                layoutLength: 400,
                items: [
                    (measuredLength: 200, growPriority: 1.0),
                    (measuredLength: 100, growPriority: 2.0)
                ], expectedRanges: [
                    0...250,
                    250...400
                ])

        }


    }

    func test_overflow() {

        func test(
            overflow: StackLayout.OverflowDistribution,
            layoutLength: CGFloat,
            items: [(measuredLength: CGFloat, shrinkPriority: CGFloat)],
            expectedRanges: [ClosedRange<CGFloat>],
            file: StaticString = #file,
            line: UInt = #line) {

            do {
                var row = Row()
                for item in items {
                    row.add(
                        growPriority: 1.0,
                        shrinkPriority: item.shrinkPriority,
                        child: TestElement(size: CGSize(width: item.measuredLength, height: 100)))
                }
                row.horizontalOverflow = overflow

                let childRanges = row
                    .layout(frame: CGRect(x: 0, y: 0, width: layoutLength, height: 100))
                    .children
                    .map { ClosedRange(uncheckedBounds: ($0.node.layoutAttributes.frame.minX, $0.node.layoutAttributes.frame.maxX))
                    }

                XCTAssertEqual(childRanges, expectedRanges, "Horizontal", file: file, line: line)
            }

            do {
                var column = Column()
                for item in items {
                    column.add(
                        growPriority: 1.0,
                        shrinkPriority: item.shrinkPriority,
                        child: TestElement(size: CGSize(width: 100, height: item.measuredLength)))
                }
                column.verticalOverflow = overflow

                let childRanges = column
                    .layout(frame: CGRect(x: 0, y: 0, width: 100, height: layoutLength))
                    .children
                    .map {
                        ClosedRange(uncheckedBounds: ($0.node.layoutAttributes.frame.minY, $0.node.layoutAttributes.frame.maxY))
                    }

                XCTAssertEqual(childRanges, expectedRanges, "Vertical", file: file, line: line)
            }

        }


        // Test single child for different overflow distributions, including different shrink priorities.
        do {
            test(
                overflow: .condenseUniformly,
                layoutLength: 100,
                items: [
                    (measuredLength: 200, shrinkPriority: 1.0)
                ], expectedRanges: [
                    0...100
                ])

            test(
                overflow: .condenseUniformly,
                layoutLength: 100,
                items: [
                    (measuredLength: 200, shrinkPriority: 0.0)
                ], expectedRanges: [
                    0...200
                ])

            test(
                overflow: .condenseProportionally,
                layoutLength: 100,
                items: [
                    (measuredLength: 200, shrinkPriority: 1.0)
                ], expectedRanges: [
                    0...100
                ])

            test(
                overflow: .condenseProportionally,
                layoutLength: 100,
                items: [
                    (measuredLength: 200, shrinkPriority: 0.0)
                ], expectedRanges: [
                    0...200
                ])
        }

        // Test with default shrink priorities
        do {

            test(
                overflow: .condenseProportionally,
                layoutLength: 200,
                items: [
                    (measuredLength: 300, shrinkPriority: 1.0),
                    (measuredLength: 100, shrinkPriority: 1.0)
                ], expectedRanges: [
                    0...150,
                    150...200
                ])

            test(
                overflow: .condenseUniformly,
                layoutLength: 300,
                items: [
                    (measuredLength: 300, shrinkPriority: 1.0),
                    (measuredLength: 100, shrinkPriority: 1.0)
                ], expectedRanges: [
                    0...250,
                    250...300
                ])

        }

        // Test with custom shrink priorities
        do {
            test(
                overflow: .condenseProportionally,
                layoutLength: 200,
                items: [
                    (measuredLength: 200, shrinkPriority: 2.0),
                    (measuredLength: 100, shrinkPriority: 1.0)
                ], expectedRanges: [
                    0...120,
                    120...200
                ])

            test(
                overflow: .condenseUniformly,
                layoutLength: 300,
                items: [
                    (measuredLength: 300, shrinkPriority: 1.0),
                    (measuredLength: 100, shrinkPriority: 4.0)
                ], expectedRanges: [
                    0...280,
                    280...300
                ])
        }


    }


}


fileprivate struct TestElement: Element {

    var size: CGSize

    init(size: CGSize = CGSize(width: 100, height: 100)) {
        self.size = size
    }

    var content: ElementContent {
        return ElementContent(intrinsicSize: size)
    }

    func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return nil
    }

}
