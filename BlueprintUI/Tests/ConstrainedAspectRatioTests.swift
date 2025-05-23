import BlueprintUI
import XCTest

class ConstrainedAspectRatioTests: XCTestCase {

    let tallRatio = AspectRatio(width: 1, height: 4)
    let wideRatio = AspectRatio(width: 4, height: 1)

    func assert(
        ratio: AspectRatio,
        mode: ConstrainedAspectRatio.ContentMode,
        constraint: SizeConstraint,
        layoutModes: [LayoutMode] = LayoutMode.testModes,
        expectedSize: CGSize,
        line: UInt = #line
    ) {
        let element = TestElement()
            .constrainedTo(aspectRatio: ratio, contentMode: mode)

        for layoutMode in layoutModes {
            layoutMode.performAsDefault {
                let size = element.content.measure(in: constraint, environment: .empty)
                XCTAssertEqual(
                    size,
                    expectedSize,
                    """
                    Element sized \(TestElement.size)
                    constrained to aspect ratio \(ratio.ratio)
                    content mode \(mode)
                    expected to be size: \(expectedSize)
                    in constraint: \(constraint)
                    layout mode: \(layoutMode)
                    """,
                    line: line
                )
            }
        }
    }

    func test_fitParent_wide() {
        func assert(
            constraint: SizeConstraint,
            layoutModes: [LayoutMode] = LayoutMode.testModes,
            expectedSize: CGSize,
            line: UInt = #line
        ) {
            self.assert(
                ratio: wideRatio,
                mode: .fitParent,
                constraint: constraint,
                layoutModes: layoutModes,
                expectedSize: expectedSize,
                line: line
            )
        }

        // Fixed large constraint
        assert(
            constraint: SizeConstraint(width: .atMost(100), height: .atMost(100)),
            expectedSize: CGSize(width: 100, height: 25)
        )
        // Fixed small constraint
        assert(
            constraint: SizeConstraint(width: .atMost(8), height: .atMost(8)),
            expectedSize: CGSize(width: 8, height: 2)
        )
        // Unconstrained height, larger width
        assert(
            constraint: SizeConstraint(width: 100),
            expectedSize: CGSize(width: 100, height: 25)
        )
        // Unconstrained height, smaller width
        assert(
            constraint: SizeConstraint(width: 8),
            expectedSize: CGSize(width: 8, height: 2)
        )
        // Unconstrained width, larger height
        assert(
            constraint: SizeConstraint(height: 100),
            expectedSize: CGSize(width: 400, height: 100)
        )
        // Unconstrained width, smaller height
        assert(
            constraint: SizeConstraint(height: 8),
            expectedSize: CGSize(width: 32, height: 8)
        )
        // Fully unconstrained
        assert(
            constraint: .unconstrained,
            expectedSize: .infinity
        )
        // Exact fit
        assert(
            constraint: SizeConstraint(width: .atMost(80), height: .atMost(20)),
            expectedSize: CGSize(width: 80, height: 20)
        )
    }

    func test_fitParent_tall() {
        func assert(
            constraint: SizeConstraint,
            layoutModes: [LayoutMode] = LayoutMode.testModes,
            expectedSize: CGSize,
            line: UInt = #line
        ) {
            self.assert(
                ratio: tallRatio,
                mode: .fitParent,
                constraint: constraint,
                layoutModes: layoutModes,
                expectedSize: expectedSize,
                line: line
            )
        }

        // Fixed large constraint
        assert(
            constraint: SizeConstraint(width: .atMost(100), height: .atMost(100)),
            expectedSize: CGSize(width: 25, height: 100)
        )
        // Fixed small constraint
        assert(
            constraint: SizeConstraint(width: .atMost(8), height: .atMost(8)),
            expectedSize: CGSize(width: 2, height: 8)
        )
        // Unconstrained height, larger width
        assert(
            constraint: SizeConstraint(width: 100),
            expectedSize: CGSize(width: 100, height: 400)
        )
        // Unconstrained height, smaller width
        assert(
            constraint: SizeConstraint(width: 8),
            expectedSize: CGSize(width: 8, height: 32)
        )
        // Unconstrained width, larger height
        assert(
            constraint: SizeConstraint(height: 100),
            expectedSize: CGSize(width: 25, height: 100)
        )
        // Unconstrained width, smaller height
        assert(
            constraint: SizeConstraint(height: 8),
            expectedSize: CGSize(width: 2, height: 8)
        )
        // Fully unconstrained
        assert(
            constraint: .unconstrained,
            expectedSize: .infinity
        )
        // Exact fit
        assert(
            constraint: SizeConstraint(width: .atMost(20), height: .atMost(80)),
            expectedSize: CGSize(width: 20, height: 80)
        )
    }

    func test_fitContent_wide() {
        func assert(
            constraint: SizeConstraint,
            layoutModes: [LayoutMode] = LayoutMode.testModes,
            expectedSize: CGSize,
            line: UInt = #line
        ) {
            self.assert(
                ratio: wideRatio,
                mode: .fitContent,
                constraint: constraint,
                layoutModes: layoutModes,
                expectedSize: expectedSize,
                line: line
            )
        }

        // Fixed large constraint
        assert(
            constraint: SizeConstraint(width: .atMost(100), height: .atMost(100)),
            expectedSize: CGSize(width: 40, height: 10)
        )
        // Fixed small constraint
        assert(
            constraint: SizeConstraint(width: .atMost(8), height: .atMost(8)),
            expectedSize: CGSize(width: 40, height: 10)
        )
        // Unconstrained height, larger width
        assert(
            constraint: SizeConstraint(width: 100),
            expectedSize: CGSize(width: 40, height: 10)
        )
        // Unconstrained height, smaller width
        assert(
            constraint: SizeConstraint(width: 8),
            expectedSize: CGSize(width: 40, height: 10)
        )
        // Unconstrained width, larger height
        assert(
            constraint: SizeConstraint(height: 100),
            expectedSize: CGSize(width: 40, height: 10)
        )
        // Unconstrained width, smaller height
        assert(
            constraint: SizeConstraint(height: 8),
            expectedSize: CGSize(width: 40, height: 10)
        )
        // Fully unconstrained
        assert(
            constraint: .unconstrained,
            expectedSize: CGSize(width: 40, height: 10)
        )
        // Exact fit
        assert(
            constraint: SizeConstraint(width: .atMost(80), height: .atMost(20)),
            expectedSize: CGSize(width: 40, height: 10)
        )
    }

    func test_fitContent_tall() {
        func assert(
            constraint: SizeConstraint,
            layoutModes: [LayoutMode] = LayoutMode.testModes,
            expectedSize: CGSize,
            line: UInt = #line
        ) {
            self.assert(
                ratio: tallRatio,
                mode: .fitContent,
                constraint: constraint,
                layoutModes: layoutModes,
                expectedSize: expectedSize,
                line: line
            )
        }

        // Fixed large constraint
        assert(
            constraint: SizeConstraint(width: .atMost(100), height: .atMost(100)),
            expectedSize: CGSize(width: 12, height: 48)
        )
        // Fixed small constraint
        assert(
            constraint: SizeConstraint(width: .atMost(8), height: .atMost(8)),
            expectedSize: CGSize(width: 12, height: 48)
        )
        // Unconstrained height, larger width
        assert(
            constraint: SizeConstraint(width: 100),
            expectedSize: CGSize(width: 12, height: 48)
        )
        // Unconstrained height, smaller width
        assert(
            constraint: SizeConstraint(width: 8),
            expectedSize: CGSize(width: 12, height: 48)
        )
        // Unconstrained width, larger height
        assert(
            constraint: SizeConstraint(height: 100),
            expectedSize: CGSize(width: 12, height: 48)
        )
        // Unconstrained width, smaller height
        assert(
            constraint: SizeConstraint(height: 8),
            expectedSize: CGSize(width: 12, height: 48)
        )
        // Fully unconstrained
        assert(
            constraint: .unconstrained,
            expectedSize: CGSize(width: 12, height: 48)
        )
        // Exact fit
        assert(
            constraint: SizeConstraint(width: .atMost(80), height: .atMost(20)),
            expectedSize: CGSize(width: 12, height: 48)
        )
    }

    func test_shrinkContent_wide() {
        func assert(
            constraint: SizeConstraint,
            layoutModes: [LayoutMode] = LayoutMode.testModes,
            expectedSize: CGSize,
            line: UInt = #line
        ) {
            self.assert(
                ratio: wideRatio,
                mode: .shrinkContent,
                constraint: constraint,
                layoutModes: layoutModes,
                expectedSize: expectedSize,
                line: line
            )
        }

        // Fixed large constraint
        assert(
            constraint: SizeConstraint(width: .atMost(100), height: .atMost(100)),
            expectedSize: CGSize(width: 12, height: 3)
        )
        // Fixed small constraint
        assert(
            constraint: SizeConstraint(width: .atMost(8), height: .atMost(8)),
            expectedSize: CGSize(width: 12, height: 3)
        )
        // Unconstrained height, larger width
        assert(
            constraint: SizeConstraint(width: 100),
            expectedSize: CGSize(width: 12, height: 3)
        )
        // Unconstrained height, smaller width
        assert(
            constraint: SizeConstraint(width: 8),
            expectedSize: CGSize(width: 12, height: 3)
        )
        // Unconstrained width, larger height
        assert(
            constraint: SizeConstraint(height: 100),
            expectedSize: CGSize(width: 12, height: 3)
        )
        // Unconstrained width, smaller height
        assert(
            constraint: SizeConstraint(height: 8),
            expectedSize: CGSize(width: 12, height: 3)
        )
        // Fully unconstrained
        assert(
            constraint: .unconstrained,
            expectedSize: CGSize(width: 12, height: 3)
        )
        // Exact fit
        assert(
            constraint: SizeConstraint(width: .atMost(80), height: .atMost(20)),
            expectedSize: CGSize(width: 12, height: 3)
        )
    }

    func test_shrinkContent_tall() {
        func assert(
            constraint: SizeConstraint,
            layoutModes: [LayoutMode] = LayoutMode.testModes,
            expectedSize: CGSize,
            line: UInt = #line
        ) {
            self.assert(
                ratio: tallRatio,
                mode: .shrinkContent,
                constraint: constraint,
                layoutModes: layoutModes,
                expectedSize: expectedSize,
                line: line
            )
        }

        // Fixed large constraint
        assert(
            constraint: SizeConstraint(width: .atMost(100), height: .atMost(100)),
            expectedSize: CGSize(width: 2.5, height: 10)
        )
        // Fixed small constraint
        assert(
            constraint: SizeConstraint(width: .atMost(8), height: .atMost(8)),
            expectedSize: CGSize(width: 2.5, height: 10)
        )
        // Unconstrained height, larger width
        assert(
            constraint: SizeConstraint(width: 100),
            expectedSize: CGSize(width: 2.5, height: 10)
        )
        // Unconstrained height, smaller width
        assert(
            constraint: SizeConstraint(width: 8),
            expectedSize: CGSize(width: 2.5, height: 10)
        )
        // Unconstrained width, larger height
        assert(
            constraint: SizeConstraint(height: 100),
            expectedSize: CGSize(width: 2.5, height: 10)
        )
        // Unconstrained width, smaller height
        assert(
            constraint: SizeConstraint(height: 8),
            expectedSize: CGSize(width: 2.5, height: 10)
        )
        // Fully unconstrained
        assert(
            constraint: .unconstrained,
            expectedSize: CGSize(width: 2.5, height: 10)
        )
        // Exact fit
        assert(
            constraint: SizeConstraint(width: .atMost(80), height: .atMost(20)),
            expectedSize: CGSize(width: 2.5, height: 10)
        )
    }

    func test_layoutContract() {
        assertLayoutContract(
            of: TestElement().constrainedTo(
                aspectRatio: wideRatio,
                contentMode: .fitParent
            )
        )

        assertLayoutContract(
            of: TestElement().constrainedTo(
                aspectRatio: tallRatio,
                contentMode: .fitParent
            )
        )

        assertLayoutContract(
            of: TestElement().constrainedTo(
                aspectRatio: wideRatio,
                contentMode: .fitContent
            )
        )

        assertLayoutContract(
            of: TestElement().constrainedTo(
                aspectRatio: tallRatio,
                contentMode: .fitContent
            )
        )

        assertLayoutContract(
            of: TestElement().constrainedTo(
                aspectRatio: wideRatio,
                contentMode: .shrinkContent
            )
        )

        assertLayoutContract(
            of: TestElement().constrainedTo(
                aspectRatio: tallRatio,
                contentMode: .shrinkContent
            )
        )
    }
}

private struct TestElement: Element {
    static let size = CGSize(width: 12, height: 10)

    var content: ElementContent {
        ElementContent(intrinsicSize: Self.size)
    }

    func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        nil
    }
}
