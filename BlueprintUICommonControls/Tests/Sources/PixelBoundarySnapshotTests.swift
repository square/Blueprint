import XCTest
import BlueprintUI
import BlueprintUICommonControls

final class PixelBoundarySnapshotTests: XCTestCase {
    func test_nestedBoxes() {
        compareSnapshot(of: NestedBoxes(), scale: 2.0)
    }

    func test_fractionRow() {
        compareSnapshot(of: FractionRow(), scale: 2.0)
    }
}

private struct NestedBoxes: ProxyElement {
    let colors: [UIColor] = [
        .cyan,
        .red,
        .green,
        .yellow,
        .blue,
        .magenta,
        .purple,
        .orange
    ]
    var depth: Int = 10

    var elementRepresentation: Element {
        guard depth > 0 else {
            return Box(backgroundColor: .white, wrapping: Spacer(size: CGSize(width: 10, height: 10)))
        }

        let color = colors[depth % colors.count]
        return Box(
            backgroundColor: color,
            wrapping: Inset(
                top: 2.0,
                bottom: 2.0,
                left: 0.3,
                right: 0.3,
                wrapping: NestedBoxes(depth: depth - 1)
            )
        )
    }
}

private struct FractionRow: ProxyElement {
    var elementRepresentation: Element {
        return Box(
            backgroundColor: .yellow,
            wrapping: ConstrainedSize(
                width: .absolute(13.0),
                wrapping: Row { row in
                    row.horizontalUnderflow = .spaceEvenly
                    for _ in 1...5 {
                        row.add(
                            child: Box(
                                backgroundColor: .red,
                                wrapping: Spacer(size: CGSize(width: 2.0, height: 5.0))
                            )
                        )
                    }
                }
            )
        )
    }
}

