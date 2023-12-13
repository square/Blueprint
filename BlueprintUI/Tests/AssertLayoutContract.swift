import BlueprintUI
import XCTest

/// Asserts that an element's layout adheres to the Layout contract, by probing its size
/// in a variety of constraints.
///
/// - Parameters:
///   - element: The element under test.
///   - file: The file in which failure occurred. Defaults to `#file`.
///   - line: The line on which failure occurred. Defaults to `#line`.
public func assertLayoutContract(
    of element: Element,
    file: StaticString = #file,
    line: UInt = #line
) {

    let content = element.content

    let constraintValues: [CGFloat] = [
        0,
        1,
        5,
        10,
        50,
        100,
        500,
        1000,
        5000,
        10000,
        .infinity,
    ]
    let adjacentConstraintValues = Array(zip(constraintValues, constraintValues.dropFirst()))

    var sizes: [SizeConstraint: CGSize] = [:]

    func sizeThatFits(width: CGFloat, height: CGFloat) -> CGSize {
        let constraint = SizeConstraint(CGSize(width: width, height: height))

        if let size = sizes[constraint] {
            return size
        }

        let size = LayoutMode.caffeinated.performAsDefault {
            content.measure(in: constraint, environment: .empty)
        }
        sizes[constraint] = size

        return size
    }

    for width in constraintValues {
        for (lowerHeight, upperHeight) in adjacentConstraintValues {
            let lowerSize = sizeThatFits(width: width, height: lowerHeight)
            let upperSize = sizeThatFits(width: width, height: upperHeight)

            if upperSize.height <= lowerHeight, lowerHeight <= upperHeight {
                XCTAssertEqual(
                    lowerSize.height,
                    upperSize.height,
                    """
                    Layout contract violation:
                      At fixed width \(width),
                      measured height \(upperHeight) => \(upperSize.height)
                      implies a range [\(upperSize.height)...\(upperHeight)] => \(upperSize.height),
                      so we expect \(lowerHeight) => \(upperSize.height)
                    However, we observed:
                      \(lowerHeight) => \(lowerSize.height)
                    """,
                    file: file,
                    line: line
                )
            } else {
                XCTAssertLessThanOrEqual(
                    lowerSize.height,
                    upperSize.height,
                    """
                    Layout contract violation:
                      At fixed width \(width),
                      measured height \(lowerHeight) => \(lowerSize.height)
                      and height \(upperHeight) => \(upperSize.height)
                    Size must grow monotonically.
                    """,
                    file: file,
                    line: line
                )
            }
        }
    }

    for height in constraintValues {
        for (lowerWidth, upperWidth) in adjacentConstraintValues {
            let lowerSize = sizeThatFits(width: lowerWidth, height: height)
            let upperSize = sizeThatFits(width: upperWidth, height: height)

            if upperSize.width <= lowerWidth, lowerWidth <= upperWidth {
                XCTAssertEqual(
                    lowerSize.width,
                    upperSize.width,
                    """
                    Layout contract violation:
                      At fixed height \(height),
                      measured width \(upperWidth) => \(upperSize.width)
                      implies a range [\(upperSize.width)...\(upperWidth)] => \(upperSize.width),
                      so we expect \(lowerWidth) => \(upperSize.width)
                    However, we observed:
                      \(lowerWidth) => \(lowerSize.width)
                    """,
                    file: file,
                    line: line
                )
            } else {
                XCTAssertLessThanOrEqual(
                    lowerSize.width,
                    upperSize.width,
                    """
                    Layout contract violation:
                      At fixed height \(height),
                      measured width \(lowerWidth) => \(lowerSize.width)
                      and width \(upperWidth) => \(upperSize.width)
                    Size must grow monotonically.
                    """,
                    file: file,
                    line: line
                )
            }
        }
    }
}
