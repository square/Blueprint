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
        let column = Column {
            TestElement()
            TestElement()
        }

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
        let row = Row {
            TestElement()
            TestElement()
        }

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
        let row = Row(minimumHorizontalSpacing: 10.0) {
            TestElement()
            TestElement()
        }

        XCTAssertEqual(row.content.measure(in: .unconstrained).width, 210)
        XCTAssertEqual(row.content.measure(in: .unconstrained).height, 100)

        let children = row
            .layout(frame: CGRect(x: 0, y: 0, width: 210, height: 100))
            .children
            .map { $0.node }

        XCTAssertEqual(children[0].layoutAttributes.frame, CGRect(x: 0, y: 0, width: 100, height: 100))
        XCTAssertEqual(children[1].layoutAttributes.frame, CGRect(x: 110, y: 0, width: 100, height: 100))
    }

    func test_columnAlignment() {
        func test(
            alignment: Column.ColumnAlignment,
            layoutCrossSize: CGFloat,
            elementCrossSize: CGFloat,
            expectedOrigin: CGFloat,
            expectedSize: CGFloat,
            file: StaticString = #file,
            line: UInt = #line
        ) {
            let column = Column(horizontalAlignment: alignment) {
                TestElement(size: CGSize(width: elementCrossSize, height: 100))
            }

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

        test(alignment: .leading, layoutCrossSize: 200, elementCrossSize: 100, expectedOrigin: 0, expectedSize: 100)
        test(alignment: .trailing, layoutCrossSize: 200, elementCrossSize: 100, expectedOrigin: 100, expectedSize: 100)
        test(alignment: .fill, layoutCrossSize: 200, elementCrossSize: 100, expectedOrigin: 0, expectedSize: 200)
        test(alignment: .center, layoutCrossSize: 200, elementCrossSize: 100, expectedOrigin: 50, expectedSize: 100)
        test(
            alignment: .align(to: .test25),
            layoutCrossSize: 200,
            elementCrossSize: 100,
            expectedOrigin: 25,
            expectedSize: 100
        )
    }

    func test_rowAlignment() {
        func test(
            alignment: Row.RowAlignment,
            layoutCrossSize: CGFloat,
            elementCrossSize: CGFloat,
            expectedOrigin: CGFloat,
            expectedSize: CGFloat,
            file: StaticString = #file,
            line: UInt = #line
        ) {
            let row = Row(verticalAlignment: alignment) {
                TestElement(size: CGSize(width: 100, height: elementCrossSize))
            }

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

        test(alignment: .top, layoutCrossSize: 200, elementCrossSize: 100, expectedOrigin: 0, expectedSize: 100)
        test(alignment: .bottom, layoutCrossSize: 200, elementCrossSize: 100, expectedOrigin: 100, expectedSize: 100)
        test(alignment: .fill, layoutCrossSize: 200, elementCrossSize: 100, expectedOrigin: 0, expectedSize: 200)
        test(alignment: .center, layoutCrossSize: 200, elementCrossSize: 100, expectedOrigin: 50, expectedSize: 100)
        test(
            alignment: .align(to: .test25),
            layoutCrossSize: 200,
            elementCrossSize: 100,
            expectedOrigin: 25,
            expectedSize: 100
        )
    }

    func test_alignmentGuides() {
        func test(
            stack: StackElement,
            layoutSize: CGSize,
            expectedSize: CGSize,
            expectedOrigins: [CGFloat],
            file: StaticString = #file,
            line: UInt = #line
        ) {
            let layoutResult = stack.layout(frame: CGRect(origin: .zero, size: layoutSize))
            let frames = layoutResult
                .children
                .map { child in child.node.layoutAttributes.frame }

            let size = stack.content.measure(in: .unconstrained)
            XCTAssertEqual(size, expectedSize, "measured size", file: file, line: line)

            XCTAssertEqual(frames.count, expectedOrigins.count, "child count", file: file, line: line)
            for i in frames.indices {
                let origin = stack.layout.axis == .horizontal
                    ? CGPoint(x: CGFloat(i) * 100, y: expectedOrigins[i])
                    : CGPoint(x: expectedOrigins[i], y: CGFloat(i) * 100)

                XCTAssertEqual(
                    frames[i],
                    CGRect(origin: origin, size: CGSize(width: 100, height: 100)),
                    "child \(i) frame",
                    file: file,
                    line: line
                )
            }
        }

        // In this test, 3 boxes are aligned to their top & bottom edges.
        // The stack size matches the size of the content and needs no further alignment.
        //
        //          ┌ ─ ─ ─ ─ ─ ─ ┬──────────┐─ ─ ─ ─ ─ ─ ─
        //                        │100       │             │
        //          │             │          │
        //                        │          │             │
        //          │             │          │
        //                        │          │             │
        //        ─ ┼┌──────────┬ ┴──────────┘─┌──────────┬ ─ guide
        //           │0         │              │0         ││
        //          ││          │              │          │
        //           │          │              │          ││
        //          ││          │              │          │
        //           │          │              │          ││
        //  anchor ▶┴┴──────────┴──────────────┴──────────┴─◀
        //
        test(
            stack: Row(verticalAlignment: .bottom) {
                TestElement()
                    .stackChild(alignmentGuide: { _ in 0 }) // align to top edge
                TestElement()
                    .stackChild(alignmentGuide: { d in d.height }) // align to bottom edge
                TestElement()
                    .stackChild(alignmentGuide: { d in d[.top] }) // align to top using another guide
            },
            layoutSize: CGSize(width: 300, height: 200),
            expectedSize: CGSize(width: 300, height: 200),
            expectedOrigins: [
                100,
                0,
                100,
            ]
        )
        // Same test on the other axis.
        test(
            stack: Column(horizontalAlignment: .trailing) {
                TestElement().stackChild(alignmentGuide: { _ in 0 })
                TestElement().stackChild(alignmentGuide: { d in d.width })
                TestElement().stackChild(alignmentGuide: { d in d[.leading] })
            },
            layoutSize: CGSize(width: 200, height: 300),
            expectedSize: CGSize(width: 200, height: 300),
            expectedOrigins: [
                100,
                0,
                100,
            ]
        )

        // In this test, 4 boxes are aligned relatively based on an arbitrary offset.
        // The relatively aligned content is larger than the stack bounds,
        // so the alignment is used to anchor the content to the center.
        // Note that the relative alignment guide does not lie at the center of the content.
        //
        //           ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┬──────────┐
        //            content bounds                         │160       │
        //           │                                       │          │
        //                                                   │          │
        //          ┌│─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─│          ├
        //           stack bounds                            │          ││
        //          ││            ┌──────────┐               └──────────┘
        //                        │50        │                          ││
        //  anchor ▶┼┼────────────┤          ├────────────────────────────◀
        //        ─ ─┌──────────┬ ┼ ─ ─ ─ ─ ─│─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┼│─ guide
        //          ││0         │ │          │
        //           │          │ │          │  ┌──────────┐            ││
        //          └│          ├ ┴──────────┘─ ┤-40       │─ ─ ─ ─ ─ ─ ─
        //           │          │               │          │            │
        //           │          │               │          │
        //           └──────────┘               │          │            │
        //           │                          │          │
        //            ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┴──────────┘─ ─ ─ ─ ─ ─ ┘
        test(
            stack: Row(verticalAlignment: .center) {
                TestElement()
                    .stackChild(alignmentGuide: { _ in 0 }) // align to top edge
                TestElement() // default (center)
                TestElement()
                    .stackChild(alignmentGuide: { d in -40 }) // align outside bounds
                TestElement()
                    .stackChild(alignmentGuide: { d in 160 }) // align outside bounds
            },
            layoutSize: CGSize(width: 400, height: 200),
            expectedSize: CGSize(width: 400, height: 300),
            expectedOrigins: [
                110,
                60,
                150,
                -50,
            ]
        )
        // Same test on the other axis.
        test(
            stack: Column(horizontalAlignment: .center) {
                TestElement().stackChild(alignmentGuide: { _ in 0 })
                TestElement()
                TestElement().stackChild(alignmentGuide: { d in -40 })
                TestElement().stackChild(alignmentGuide: { d in 160 })
            },
            layoutSize: CGSize(width: 200, height: 400),
            expectedSize: CGSize(width: 300, height: 400),
            expectedOrigins: [
                110,
                60,
                150,
                -50,
            ]
        )

        // This test mimicks baseline alignment of text.
        // The relatively aligned content is smaller than the stack bounds,
        // so the alignment is used to anchor the content to the bottom.
        //
        //          ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─
        //           stack bounds                          │
        //          │
        //                                          ┌──────┼── content bounds
        //          │                               │
        //           ┌ ─ ─ ─ ─ ─ ─┌──────────┬ ─ ─ ─│─ ─ ─ │
        //          │┌──────────┐ │100       │            │
        //           │90        │ │          │ ┌──────────┐│
        //          ││          │ │          │ │80        │
        //           │          │ │          │ │          ││
        //          ││          │ │          │ │          │
        //        ─ ─│─ ─ ─ ─ ─ ┼ ┴──────────┘─│─ ─ ─ ─ ─ ┼│─  guide
        //          │└──────────┘              │          │
        //  anchor ▶─┴─────────────────────────┴──────────┴┴◀
        //
        test(
            stack: Row(verticalAlignment: .bottom) {
                TestElement()
                    .stackChild(alignmentGuide: { d in d.height - 10 }) // 10 from bottom
                TestElement() // default (bottom)
                TestElement()
                    .stackChild(alignmentGuide: { d in d.height - 20 }) // 20 from bottom
            },
            layoutSize: CGSize(width: 300, height: 200),
            expectedSize: CGSize(width: 300, height: 120),
            expectedOrigins: [
                90,
                80,
                100,
            ]
        )
        // Same test on the other axis.
        test(
            stack: Column(horizontalAlignment: .trailing) {
                TestElement().stackChild(alignmentGuide: { d in d.width - 10 })
                TestElement()
                TestElement().stackChild(alignmentGuide: { d in d.width - 20 })
            },
            layoutSize: CGSize(width: 200, height: 300),
            expectedSize: CGSize(width: 120, height: 300),
            expectedOrigins: [
                90,
                80,
                100,
            ]
        )
    }

    func test_crossConstraints() {
        func test(
            crossConstraint: SizeConstraint.Axis,
            layoutSize: CGFloat,
            expectedSize: CGFloat,
            file: StaticString = #file,
            line: UInt = #line
        ) {
            do {
                let row = Row(verticalAlignment: .fill) {
                    TestElement(size: CGSize(width: 100, height: 100))
                }

                let constraint = SizeConstraint(width: .unconstrained, height: crossConstraint)
                let size = row.content.measure(in: constraint)

                XCTAssertEqual(size.height, expectedSize, "Horizontal size", file: file, line: line)

                let height = row
                    .layout(frame: CGRect(x: 0, y: 0, width: 100, height: layoutSize))
                    .children[0]
                    .node
                    .layoutAttributes
                    .frame
                    .height

                XCTAssertEqual(height, layoutSize, "Horizontal layout", file: file, line: line)
            }

            do {
                let column = Column(horizontalAlignment: .fill) {
                    TestElement(size: CGSize(width: 100, height: 100))
                }

                let constraint = SizeConstraint(width: crossConstraint, height: .unconstrained)
                let size = column.content.measure(in: constraint)

                XCTAssertEqual(size.width, expectedSize, "Vertical size", file: file, line: line)

                let width = column
                    .layout(frame: CGRect(x: 0, y: 0, width: layoutSize, height: 100))
                    .children[0]
                    .node
                    .layoutAttributes
                    .frame
                    .width

                XCTAssertEqual(width, layoutSize, "Vertical layout", file: file, line: line)
            }
        }

        test(crossConstraint: .unconstrained, layoutSize: 1000, expectedSize: 100)
        test(crossConstraint: .atMost(200), layoutSize: 200, expectedSize: 100)
        test(crossConstraint: .atMost(50), layoutSize: 50, expectedSize: 50)
    }

    func test_underflow() {

        func test(
            underflow: StackLayout.UnderflowDistribution,
            layoutLength: CGFloat,
            items: [(measuredLength: CGFloat, growPriority: CGFloat)],
            expectedRanges: [ClosedRange<CGFloat>],
            file: StaticString = #file,
            line: UInt = #line
        ) {

            let unconstrainedSize = items
                .map { $0.measuredLength }
                .reduce(0, +)

            do {
                let row = Row(items) { item in
                    TestElement(size: CGSize(width: item.measuredLength, height: 100))
                        .stackChild(sizing: .init(growPriority: item.growPriority))
                } configure: {
                    $0.horizontalUnderflow = underflow
                }

                let size = row.content.measure(
                    in: SizeConstraint(
                        width: .atMost(layoutLength),
                        height: .atMost(100)
                    ))
                XCTAssertEqual(
                    size,
                    CGSize(width: unconstrainedSize, height: 100),
                    "Horizontal size",
                    file: file,
                    line: line
                )

                let childRanges = row
                    .layout(frame: CGRect(x: 0, y: 0, width: layoutLength, height: 100))
                    .children
                    .map {
                        ClosedRange(uncheckedBounds: (
                            $0.node.layoutAttributes.frame.minX,
                            $0.node.layoutAttributes.frame.maxX
                        ))
                    }

                XCTAssertEqual(childRanges, expectedRanges, "Horizontal layout", file: file, line: line)
            }

            do {
                let column = Column(items) { item in
                    TestElement(size: CGSize(width: 100, height: item.measuredLength))
                        .stackChild(sizing: .init(growPriority: item.growPriority))
                } configure: {
                    $0.verticalUnderflow = underflow
                }

                let size = column.content.measure(
                    in: SizeConstraint(
                        width: .atMost(100),
                        height: .atMost(layoutLength)
                    ))
                XCTAssertEqual(
                    size,
                    CGSize(width: 100, height: unconstrainedSize),
                    "Vertical size",
                    file: file,
                    line: line
                )

                let childRanges = column
                    .layout(frame: CGRect(x: 0, y: 0, width: 100, height: layoutLength))
                    .children
                    .map {
                        ClosedRange(uncheckedBounds: (
                            $0.node.layoutAttributes.frame.minY,
                            $0.node.layoutAttributes.frame.maxY
                        ))
                    }

                XCTAssertEqual(childRanges, expectedRanges, "Vertical layout", file: file, line: line)
            }

        }

        // Ensure that elements of size zero do not result in NaN in the outputted frames.

        do {
            // Note: Only applicable to `growProportionally`.

            test(
                underflow: .growProportionally,
                layoutLength: 100,
                items: [
                    (measuredLength: 0, growPriority: 1.0),
                    (measuredLength: 0, growPriority: 1.0),
                ],
                expectedRanges: [
                    0...0,
                    0...0,
                ]
            )
        }

        // Test single child for different underflow distributions, including different grow priorities.
        do {
            test(
                underflow: .spaceEvenly,
                layoutLength: 200,
                items: [
                    (measuredLength: 100, growPriority: 1.0),
                ],
                expectedRanges: [
                    0...100,
                ]
            )

            test(
                underflow: .spaceEvenly,
                layoutLength: 200,
                items: [
                    (measuredLength: 100, growPriority: 0.0),
                ],
                expectedRanges: [
                    0...100,
                ]
            )

            test(
                underflow: .growProportionally,
                layoutLength: 200,
                items: [
                    (measuredLength: 100, growPriority: 1.0),
                ],
                expectedRanges: [
                    0...200,
                ]
            )

            test(
                underflow: .growProportionally,
                layoutLength: 200,
                items: [
                    (measuredLength: 100, growPriority: 0.0),
                ],
                expectedRanges: [
                    0...100,
                ]
            )

            test(
                underflow: .growUniformly,
                layoutLength: 200,
                items: [
                    (measuredLength: 100, growPriority: 1.0),
                ],
                expectedRanges: [
                    0...200,
                ]
            )

            test(
                underflow: .growUniformly,
                layoutLength: 200,
                items: [
                    (measuredLength: 100, growPriority: 0.0),
                ],
                expectedRanges: [
                    0...100,
                ]
            )

            test(
                underflow: .justifyToStart,
                layoutLength: 200,
                items: [
                    (measuredLength: 100, growPriority: 0.0),
                ],
                expectedRanges: [
                    0...100,
                ]
            )

            test(
                underflow: .justifyToStart,
                layoutLength: 200,
                items: [
                    (measuredLength: 100, growPriority: 1.0),
                ],
                expectedRanges: [
                    0...100,
                ]
            )

            test(
                underflow: .justifyToCenter,
                layoutLength: 200,
                items: [
                    (measuredLength: 100, growPriority: 0.0),
                ],
                expectedRanges: [
                    50...150,
                ]
            )

            test(
                underflow: .justifyToCenter,
                layoutLength: 10,
                items: [
                    (measuredLength: 5, growPriority: 0.0),
                ],
                expectedRanges: [
                    2.5...7.5,
                ]
            )

            test(
                underflow: .justifyToCenter,
                layoutLength: 15,
                items: [
                    (measuredLength: 12, growPriority: 0.0),
                ],
                expectedRanges: [
                    1.5...13.5,
                ]
            )

            test(
                underflow: .justifyToCenter,
                layoutLength: 200,
                items: [
                    (measuredLength: 100, growPriority: 1.0),
                ],
                expectedRanges: [
                    50...150,
                ]
            )

            test(
                underflow: .justifyToEnd,
                layoutLength: 200,
                items: [
                    (measuredLength: 100, growPriority: 0.0),
                ],
                expectedRanges: [
                    100...200,
                ]
            )

            test(
                underflow: .justifyToEnd,
                layoutLength: 200,
                items: [
                    (measuredLength: 100, growPriority: 1.0),
                ],
                expectedRanges: [
                    100...200,
                ]
            )
        }

        // Test with default grow priorities
        do {

            test(
                underflow: .spaceEvenly,
                layoutLength: 400, items: [
                    (measuredLength: 100, growPriority: 1.0),
                    (measuredLength: 100, growPriority: 1.0),
                ], expectedRanges: [
                    0...100,
                    300...400,
                ]
            )

            test(
                underflow: .growUniformly,
                layoutLength: 400, items: [
                    (measuredLength: 200, growPriority: 1.0),
                    (measuredLength: 100, growPriority: 1.0),
                ], expectedRanges: [
                    0...250,
                    250...400,
                ]
            )

            test(
                underflow: .growProportionally,
                layoutLength: 600, items: [
                    (measuredLength: 200, growPriority: 1.0),
                    (measuredLength: 100, growPriority: 1.0),
                ], expectedRanges: [
                    0...400,
                    400...600,
                ]
            )

            test(
                underflow: .justifyToStart,
                layoutLength: 400, items: [
                    (measuredLength: 100, growPriority: 1.0),
                    (measuredLength: 100, growPriority: 1.0),
                ], expectedRanges: [
                    0...100,
                    100...200,
                ]
            )

            test(
                underflow: .justifyToCenter,
                layoutLength: 400, items: [
                    (measuredLength: 100, growPriority: 1.0),
                    (measuredLength: 100, growPriority: 1.0),
                ], expectedRanges: [
                    100...200,
                    200...300,
                ]
            )

            test(
                underflow: .justifyToEnd,
                layoutLength: 400, items: [
                    (measuredLength: 100, growPriority: 1.0),
                    (measuredLength: 100, growPriority: 1.0),
                ], expectedRanges: [
                    200...300,
                    300...400,
                ]
            )

        }

        // Test with custom grow priorities
        do {

            test(
                underflow: .spaceEvenly,
                layoutLength: 400,
                items: [
                    (measuredLength: 100, growPriority: 3.0),
                    (measuredLength: 100, growPriority: 1.0),
                ], expectedRanges: [
                    0...100,
                    300...400,
                ]
            )

            test(
                underflow: .growUniformly,
                layoutLength: 600,
                items: [
                    (measuredLength: 100, growPriority: 3.0),
                    (measuredLength: 100, growPriority: 1.0),
                ], expectedRanges: [
                    0...400,
                    400...600,
                ]
            )

            test(
                underflow: .growProportionally,
                layoutLength: 400,
                items: [
                    (measuredLength: 200, growPriority: 1.0),
                    (measuredLength: 100, growPriority: 2.0),
                ], expectedRanges: [
                    0...250,
                    250...400,
                ]
            )

            test(
                underflow: .justifyToStart,
                layoutLength: 400,
                items: [
                    (measuredLength: 100, growPriority: 3.0),
                    (measuredLength: 100, growPriority: 1.0),
                ], expectedRanges: [
                    0...100,
                    100...200,
                ]
            )

            test(
                underflow: .justifyToCenter,
                layoutLength: 400,
                items: [
                    (measuredLength: 100, growPriority: 3.0),
                    (measuredLength: 100, growPriority: 1.0),
                ], expectedRanges: [
                    100...200,
                    200...300,
                ]
            )

            test(
                underflow: .justifyToEnd,
                layoutLength: 400,
                items: [
                    (measuredLength: 100, growPriority: 3.0),
                    (measuredLength: 100, growPriority: 1.0),
                ], expectedRanges: [
                    200...300,
                    300...400,
                ]
            )
        }
    }

    func test_overflow() {
        func test(
            overflow: StackLayout.OverflowDistribution,
            layoutLength: CGFloat,
            items: [(measuredLength: CGFloat, shrinkPriority: CGFloat)],
            expectedRanges: [ClosedRange<CGFloat>],
            file: StaticString = #file,
            line: UInt = #line
        ) {

            let minSize = items
                .map { $0.shrinkPriority.isZero ? $0.measuredLength : 0 }
                .reduce(0, +)

            do {
                let row = Row(items) { item in
                    TestElement(size: CGSize(width: item.measuredLength, height: 100))
                        .stackChild(sizing: .init(shrinkPriority: item.shrinkPriority))
                } configure: {
                    $0.horizontalOverflow = overflow
                }

                let size = row.content.measure(
                    in: SizeConstraint(
                        width: .atMost(layoutLength),
                        height: .atMost(100)
                    ))
                XCTAssertEqual(
                    size,
                    CGSize(width: max(layoutLength, minSize), height: 100),
                    "Horizontal size",
                    file: file,
                    line: line
                )

                let childRanges = row
                    .layout(frame: CGRect(x: 0, y: 0, width: layoutLength, height: 100))
                    .children
                    .map { ClosedRange(uncheckedBounds: (
                        $0.node.layoutAttributes.frame.minX,
                        $0.node.layoutAttributes.frame.maxX
                    ))
                    }

                XCTAssertEqual(childRanges, expectedRanges, "Horizontal layout", file: file, line: line)
            }

            do {
                let column = Column(items) { item in
                    TestElement(size: CGSize(width: 100, height: item.measuredLength))
                        .stackChild(sizing: .init(shrinkPriority: item.shrinkPriority))
                } configure: {
                    $0.verticalOverflow = overflow
                }

                let size = column.content.measure(
                    in: SizeConstraint(
                        width: .atMost(100),
                        height: .atMost(layoutLength)
                    ))
                XCTAssertEqual(
                    size,
                    CGSize(width: 100, height: max(layoutLength, minSize)),
                    "Vertical size",
                    file: file,
                    line: line
                )

                let childRanges = column
                    .layout(frame: CGRect(x: 0, y: 0, width: 100, height: layoutLength))
                    .children
                    .map {
                        ClosedRange(uncheckedBounds: (
                            $0.node.layoutAttributes.frame.minY,
                            $0.node.layoutAttributes.frame.maxY
                        ))
                    }

                XCTAssertEqual(childRanges, expectedRanges, "Vertical layout", file: file, line: line)
            }

        }

        // Ensure that elements of size zero do not result in NaN in the outputted frames.

        do {
            // Note: Only applicable to `condenseProportionally`.

            test(
                overflow: .condenseProportionally,

                // Requires zero, otherwise we will never have an overflow (which is >= to content size).
                layoutLength: 0,

                items: [
                    (measuredLength: 0.0, shrinkPriority: 1.0),
                    (measuredLength: 0.0, shrinkPriority: 1.0),
                ],
                expectedRanges: [
                    0...0,
                    0...0,
                ]
            )
        }

        // Test single child for different overflow distributions, including different shrink priorities.
        do {
            test(
                overflow: .condenseUniformly,
                layoutLength: 100,
                items: [
                    (measuredLength: 200, shrinkPriority: 1.0),
                ], expectedRanges: [
                    0...100,
                ]
            )

            test(
                overflow: .condenseUniformly,
                layoutLength: 100,
                items: [
                    (measuredLength: 200, shrinkPriority: 0.0),
                ], expectedRanges: [
                    0...200,
                ]
            )

            test(
                overflow: .condenseProportionally,
                layoutLength: 100,
                items: [
                    (measuredLength: 200, shrinkPriority: 1.0),
                ], expectedRanges: [
                    0...100,
                ]
            )

            test(
                overflow: .condenseProportionally,
                layoutLength: 100,
                items: [
                    (measuredLength: 200, shrinkPriority: 0.0),
                ], expectedRanges: [
                    0...200,
                ]
            )
        }

        // Test with default shrink priorities
        do {

            test(
                overflow: .condenseProportionally,
                layoutLength: 200,
                items: [
                    (measuredLength: 300, shrinkPriority: 1.0),
                    (measuredLength: 100, shrinkPriority: 1.0),
                ], expectedRanges: [
                    0...150,
                    150...200,
                ]
            )

            test(
                overflow: .condenseUniformly,
                layoutLength: 300,
                items: [
                    (measuredLength: 300, shrinkPriority: 1.0),
                    (measuredLength: 100, shrinkPriority: 1.0),
                ], expectedRanges: [
                    0...250,
                    250...300,
                ]
            )

        }

        // Test with custom shrink priorities
        do {
            test(
                overflow: .condenseProportionally,
                layoutLength: 200,
                items: [
                    (measuredLength: 200, shrinkPriority: 2.0),
                    (measuredLength: 100, shrinkPriority: 1.0),
                ], expectedRanges: [
                    0...120,
                    120...200,
                ]
            )

            test(
                overflow: .condenseUniformly,
                layoutLength: 300,
                items: [
                    (measuredLength: 300, shrinkPriority: 1.0),
                    (measuredLength: 100, shrinkPriority: 4.0),
                ], expectedRanges: [
                    0...280,
                    280...300,
                ]
            )
        }


    }

    func test_flexibleContents() {
        enum TestItem {
            case flex
            case fixed

            func element(on axis: StackLayout.Axis) -> Element {
                switch self {
                case .fixed:
                    return Spacer(size: CGSize(width: 10, height: 10))
                case .flex:
                    return WrappingElement(axis: axis)
                }
            }
        }

        func test(
            items: [(item: TestItem, priority: CGFloat)],
            expectedSizes: [StackLayout.Vector],
            file: StaticString = #file,
            line: UInt = #line
        ) {
            do {
                let row = Row(items) { pair in
                    pair.item.element(on: .horizontal).stackChild(
                        sizing: .init(growPriority: pair.priority, shrinkPriority: pair.priority)
                    )
                } configure: {
                    $0.horizontalOverflow = .condenseUniformly
                }

                let sizes = row
                    .layout(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
                    .children
                    .map { child -> CGSize in
                        child.node.layoutAttributes.frame.size.rounded()
                    }

                XCTAssertEqual(
                    sizes,
                    expectedSizes.map { $0.size(axis: .horizontal) },
                    "Horizontal",
                    file: file,
                    line: line
                )
            }

            do {
                let column = Column(items) { pair in
                    pair.item.element(on: .vertical).stackChild(
                        sizing: .init(growPriority: pair.priority, shrinkPriority: pair.priority)
                    )
                } configure: {
                    $0.verticalOverflow = .condenseUniformly
                }

                let sizes = column
                    .layout(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
                    .children
                    .map { child -> CGSize in
                        child.node.layoutAttributes.frame.size.rounded()
                    }

                XCTAssertEqual(
                    sizes,
                    expectedSizes.map { $0.size(axis: .vertical) },
                    "Vertical",
                    file: file,
                    line: line
                )
            }
        }

        test(
            items: [
                (item: .flex, priority: 1)
            ],
            expectedSizes: [
                StackLayout.Vector(axis: 100, cross: 10)
            ]
        )

        test(
            items: [
                (item: .flex, priority: 1),
                (item: .flex, priority: 1)
            ],
            expectedSizes: [
                StackLayout.Vector(axis: 50, cross: 20),
                StackLayout.Vector(axis: 50, cross: 20)
            ]
        )

        test(
            items: [
                (item: .flex, priority: 1),
                (item: .flex, priority: 3)
            ],
            expectedSizes: [
                StackLayout.Vector(axis: 75, cross: 20), // 7 x 2
                StackLayout.Vector(axis: 25, cross: 50) // 2 x 5
            ]
        )

        test(
            items: [
                (item: .fixed, priority: 0),
                (item: .flex, priority: 1)
            ],
            expectedSizes: [
                StackLayout.Vector(axis: 10, cross: 10),
                StackLayout.Vector(axis: 90, cross: 20)
            ]
        )

        test(
            // overflow of 120
            items: [
                (item: .fixed, priority: 0),
                (item: .flex, priority: 2), // shrinks by 80
                (item: .flex, priority: 1), // shrinks by 40
                (item: .fixed, priority: 0)
            ],
            expectedSizes: [
                StackLayout.Vector(axis: 10, cross: 10),
                StackLayout.Vector(axis: 20, cross: 50), // 2 x 5
                StackLayout.Vector(axis: 60, cross: 20), // 6 x 2
                StackLayout.Vector(axis: 10, cross: 10)
            ]
        )
    }

    /// When constrained along `axis`, this element's content "flows" and grows along the cross axis,
    /// similar to text wrapping.
    private struct WrappingElement: Element {
        var itemSize = CGSize(width: 10, height: 10)
        var itemCount = 10
        var axis: StackLayout.Axis

        var content: ElementContent {
            ElementContent { constraint -> CGSize in
                switch self.axis {
                case .horizontal:
                    let itemsPerLine = max(1, Int(constraint.width.maximum / self.itemSize.width))
                    let lineCount = (self.itemCount + itemsPerLine - 1) / itemsPerLine
                    return CGSize(
                        width: CGFloat(itemsPerLine) * self.itemSize.width,
                        height: CGFloat(lineCount) * self.itemSize.height
                    )

                case .vertical:
                    let itemsPerColumn = max(1, Int(constraint.height.maximum / self.itemSize.height))
                    let columnCount = (self.itemCount + itemsPerColumn - 1) / itemsPerColumn
                    let size = CGSize(
                        width: CGFloat(columnCount) * self.itemSize.width,
                        height: CGFloat(itemsPerColumn) * self.itemSize.height
                    )
                    return size
                }
            }
        }

        func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
            nil
        }
    }
}

extension CGSize {
    fileprivate func rounded(_ rule: FloatingPointRoundingRule = .toNearestOrAwayFromZero) -> CGSize {
        CGSize(
            width: width.rounded(rule),
            height: height.rounded(rule)
        )
    }
}

fileprivate struct TestElement: Element {

    var size: CGSize

    init(size: CGSize = CGSize(width: 100, height: 100)) {
        self.size = size
    }

    var content: ElementContent {
        ElementContent(intrinsicSize: size)
    }

    func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        nil
    }

}

extension HorizontalAlignment {
    enum Test25: AlignmentID {
        static func defaultValue(in d: ElementDimensions) -> CGFloat {
            d.width * 0.25
        }
    }

    static let test25 = HorizontalAlignment(Test25.self)
}

extension VerticalAlignment {
    enum Test25: AlignmentID {
        static func defaultValue(in d: ElementDimensions) -> CGFloat {
            d.height * 0.25
        }
    }

    static let test25 = VerticalAlignment(Test25.self)
}
