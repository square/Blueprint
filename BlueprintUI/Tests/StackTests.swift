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

        XCTAssertEqual(column.content.size(in: .unconstrained).width, 100)
        XCTAssertEqual(column.content.size(in: .unconstrained).height, 200)

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

        XCTAssertEqual(row.content.size(in: .unconstrained).width, 200)
        XCTAssertEqual(row.content.size(in: .unconstrained).height, 100)

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

        XCTAssertEqual(row.content.size(in: .unconstrained).width, 210)
        XCTAssertEqual(row.content.size(in: .unconstrained).height, 100)

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

    func test_crossConstraints() {
        func test(
            crossConstraint: SizeConstraint.Axis,
            layoutSize: CGFloat,
            expectedSize: CGFloat,
            file: StaticString = #file,
            line: UInt = #line
        ) {
            do {
                let row = Row { row in
                    row.verticalAlignment = .fill
                    row.add(child: TestElement(size: CGSize(width: 100, height: 100)))
                }

                let constraint = SizeConstraint(width: .unconstrained, height: crossConstraint)
                let size = row.content.size(in: constraint)

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
                let column = Column { column in
                    column.horizontalAlignment = .fill
                    column.add(child: TestElement(size: CGSize(width: 100, height: 100)))
                }

                let constraint = SizeConstraint(width: crossConstraint, height: .unconstrained)
                let size = column.content.size(in: constraint)

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
                var row = Row()
                for item in items {
                    row.add(
                        growPriority: item.growPriority,
                        shrinkPriority: 1.0,
                        child: TestElement(size: CGSize(width: item.measuredLength, height: 100)))
                }
                row.horizontalUnderflow = underflow

                let size = row.content.size(
                    in: SizeConstraint(
                        width: .atMost(layoutLength),
                        height: .atMost(100)))
                XCTAssertEqual(
                    size,
                    CGSize(width: unconstrainedSize, height: 100),
                    "Horizontal size",
                    file: file,
                    line: line)

                let childRanges = row
                    .layout(frame: CGRect(x: 0, y: 0, width: layoutLength, height: 100))
                    .children
                    .map {
                        ClosedRange(uncheckedBounds: ($0.node.layoutAttributes.frame.minX, $0.node.layoutAttributes.frame.maxX))
                    }

                XCTAssertEqual(childRanges, expectedRanges, "Horizontal layout", file: file, line: line)
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

                let size = column.content.size(
                    in: SizeConstraint(
                        width: .atMost(100),
                        height: .atMost(layoutLength)))
                XCTAssertEqual(
                    size,
                    CGSize(width: 100, height: unconstrainedSize),
                    "Vertical size",
                    file: file,
                    line: line)

                let childRanges = column
                    .layout(frame: CGRect(x: 0, y: 0, width: 100, height: layoutLength))
                    .children
                    .map {
                        ClosedRange(uncheckedBounds: ($0.node.layoutAttributes.frame.minY, $0.node.layoutAttributes.frame.maxY))
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
                    0...0
                ]
            )
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

            test(
                underflow: .justifyToStart,
                layoutLength: 200,
                items: [
                    (measuredLength: 100, growPriority: 0.0)
                ],
                expectedRanges: [
                    0...100
                ])

            test(
                underflow: .justifyToStart,
                layoutLength: 200,
                items: [
                    (measuredLength: 100, growPriority: 1.0)
                ],
                expectedRanges: [
                    0...100
                ])

            test(
                underflow: .justifyToCenter,
                layoutLength: 200,
                items: [
                    (measuredLength: 100, growPriority: 0.0)
                ],
                expectedRanges: [
                    50...150
                ])

            test(
                underflow: .justifyToCenter,
                layoutLength: 10,
                items: [
                    (measuredLength: 5, growPriority: 0.0)
                ],
                expectedRanges: [
                    3...8
                ])

            test(
                underflow: .justifyToCenter,
                layoutLength: 15,
                items: [
                    (measuredLength: 12, growPriority: 0.0)
                ],
                expectedRanges: [
                    2...14
                ])

            test(
                underflow: .justifyToCenter,
                layoutLength: 200,
                items: [
                    (measuredLength: 100, growPriority: 1.0)
                ],
                expectedRanges: [
                    50...150
                ])

            test(
                underflow: .justifyToEnd,
                layoutLength: 200,
                items: [
                    (measuredLength: 100, growPriority: 0.0)
                ],
                expectedRanges: [
                    100...200
                ])

            test(
                underflow: .justifyToEnd,
                layoutLength: 200,
                items: [
                    (measuredLength: 100, growPriority: 1.0)
                ],
                expectedRanges: [
                    100...200
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

            test(
                underflow: .justifyToStart,
                layoutLength: 400, items: [
                    (measuredLength: 100, growPriority: 1.0),
                    (measuredLength: 100, growPriority: 1.0)
                ], expectedRanges: [
                    0...100,
                    100...200
                ])

            test(
                underflow: .justifyToCenter,
                layoutLength: 400, items: [
                    (measuredLength: 100, growPriority: 1.0),
                    (measuredLength: 100, growPriority: 1.0)
                ], expectedRanges: [
                    100...200,
                    200...300
                ])

            test(
                underflow: .justifyToEnd,
                layoutLength: 400, items: [
                    (measuredLength: 100, growPriority: 1.0),
                    (measuredLength: 100, growPriority: 1.0)
                ], expectedRanges: [
                    200...300,
                    300...400
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

            test(
                underflow: .justifyToStart,
                layoutLength: 400,
                items: [
                    (measuredLength: 100, growPriority: 3.0),
                    (measuredLength: 100, growPriority: 1.0)
                ], expectedRanges: [
                    0...100,
                    100...200
                ])

            test(
                underflow: .justifyToCenter,
                layoutLength: 400,
                items: [
                    (measuredLength: 100, growPriority: 3.0),
                    (measuredLength: 100, growPriority: 1.0)
                ], expectedRanges: [
                    100...200,
                    200...300
                ])

            test(
                underflow: .justifyToEnd,
                layoutLength: 400,
                items: [
                    (measuredLength: 100, growPriority: 3.0),
                    (measuredLength: 100, growPriority: 1.0)
                ], expectedRanges: [
                    200...300,
                    300...400
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
            line: UInt = #line
        ) {

            let minSize = items
                .map { $0.shrinkPriority.isZero ? $0.measuredLength : 0 }
                .reduce(0, +)

            do {
                var row = Row()
                for item in items {
                    row.add(
                        growPriority: 1.0,
                        shrinkPriority: item.shrinkPriority,
                        child: TestElement(size: CGSize(width: item.measuredLength, height: 100)))
                }
                row.horizontalOverflow = overflow

                let size = row.content.size(
                    in: SizeConstraint(
                        width: .atMost(layoutLength),
                        height: .atMost(100)))
                XCTAssertEqual(
                    size,
                    CGSize(width: max(layoutLength, minSize), height: 100),
                    "Horizontal size",
                    file: file,
                    line: line)

                let childRanges = row
                    .layout(frame: CGRect(x: 0, y: 0, width: layoutLength, height: 100))
                    .children
                    .map { ClosedRange(uncheckedBounds: ($0.node.layoutAttributes.frame.minX, $0.node.layoutAttributes.frame.maxX))
                    }

                XCTAssertEqual(childRanges, expectedRanges, "Horizontal layout", file: file, line: line)
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

                let size = column.content.size(
                    in: SizeConstraint(
                        width: .atMost(100),
                        height: .atMost(layoutLength)))
                XCTAssertEqual(
                    size,
                    CGSize(width: 100, height: max(layoutLength, minSize)),
                    "Vertical size",
                    file: file,
                    line: line)

                let childRanges = column
                    .layout(frame: CGRect(x: 0, y: 0, width: 100, height: layoutLength))
                    .children
                    .map {
                        ClosedRange(uncheckedBounds: ($0.node.layoutAttributes.frame.minY, $0.node.layoutAttributes.frame.maxY))
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
                    0...0
                ]
            )
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
                let row = Row { row in
                    row.horizontalOverflow = .condenseUniformly
                    for (item, priority) in items {
                        row.add(
                            growPriority: priority,
                            shrinkPriority: priority,
                            child: item.element(on: .horizontal))
                    }
                }

                let sizes = row
                    .layout(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
                    .children
                    .map { child -> CGSize in
                        return child.node.layoutAttributes.frame.size.rounded()
                    }

                XCTAssertEqual(
                    sizes,
                    expectedSizes.map { $0.size(axis: .horizontal) },
                    "Horizontal",
                    file: file,
                    line: line)
            }

            do {
                let column = Column { column in
                    column.verticalOverflow = .condenseUniformly
                    for (item, priority) in items {
                        column.add(
                            growPriority: priority,
                            shrinkPriority: priority,
                            child: item.element(on: .vertical))
                    }
                }

                let sizes = column
                    .layout(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
                    .children
                    .map { child -> CGSize in
                        return child.node.layoutAttributes.frame.size.rounded()
                    }

                XCTAssertEqual(
                    sizes,
                    expectedSizes.map { $0.size(axis: .vertical) },
                    "Vertical",
                    file: file,
                    line: line)
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
                StackLayout.Vector(axis: 25, cross: 50)  // 2 x 5
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
                (item: .flex, priority: 2),  // shrinks by 80
                (item: .flex, priority: 1),  // shrinks by 40
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
            return ElementContent { (constraint) -> CGSize in
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

        func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
            return nil
        }
    }
}

private extension CGSize {
    func rounded(_ rule: FloatingPointRoundingRule = .toNearestOrAwayFromZero) -> CGSize {
        return CGSize(
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
        return ElementContent(intrinsicSize: size)
    }

    func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return nil
    }

}
