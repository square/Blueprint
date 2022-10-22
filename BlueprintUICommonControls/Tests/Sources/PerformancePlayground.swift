//
//  PerformancePlayground.swift
//  BlueprintUI-Unit-Tests
//
//  Created by Kyle Van Essen on 6/23/20.
//

import XCTest
@testable import BlueprintUI
@testable import BlueprintUICommonControls


class PerformancePlayground: XCTestCase {
    let lipsumStrings = [
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
        "Integer molestie et felis at sodales.",
        "Donec varius, orci vel suscipit hendrerit, risus massa ornare dui, at gravida elit sapien at lorem.",
        "Nunc in ipsum porttitor, tincidunt est eu, euismod odio.",
        "Duis posuere nunc sed mi auctor, in dictum elit iaculis.",
        "Ut vel varius est. Duis efficitur vel lorem quis tempor.",
        "Nulla porttitor, mi nec posuere bibendum, turpis ipsum ultrices tortor, a placerat sapien augue quis sem.",
        "Cras volutpat nisl vitae elit convallis, quis tempor massa faucibus.",
    ]

    override func invokeTest() {
        // Uncomment this line to run performance metrics, eg in Instruments.app.
        super.invokeTest()
    }

    func test_kareem() {

        let gridSize = 100

        let model: [[Int]] = {
            var cols = [[Int]]()
            for i in 0..<gridSize {
                var row = [Int]()
                for j in 0..<gridSize {
                    row.append(0)
                }
                cols.append(row)
            }
            return cols
        }()

        let element = Column { col in
            for (i, values) in model.enumerated() {
                col.horizontalAlignment = .fill
                let row = Row { row in
                    for (j, value) in values.enumerated() {
                        let label = Label(text: String(value))
                            .centered()
                            .constrainedTo(size: .init(width: 20, height: 20))
                            .box(background: .red)
                            .tappable {}
                        row.add(child: label)
                    }
                }
                col.add(child: row)
            }
        }.inset(uniform: 20)

        let view = BlueprintView(frame: CGRect(x: 0.0, y: 0.0, width: 1000.0, height: 1000.0))

        determineAverage(for: 2.0) {
            view.element = element
            view.layoutIfNeeded()
        }
    }

    func test_repeated_layouts() {
        let element = Column(alignment: .fill) {

            for index in 1...500 {
                Row(alignment: .fill) {
                    Box(backgroundColor: .red)
                        .constrainedTo(size: CGSize(width: 100, height: 100))
                        .stackLayoutChild(priority: .fixed)

                    Label(text: "This is test label number #\(index)")
                        .stackLayoutChild(priority: .flexible)
                }
            }
        }
        .scrollable()

        let view = BlueprintView(frame: CGRect(x: 0.0, y: 0.0, width: 200.0, height: 500.0))

        determineAverage(for: 3.0) {
            view.element = element
            view.layoutIfNeeded()
        }
    }

    func test_rows_with_one_flexible_element_simple() {

        let row = Row(alignment: .fill, underflow: .growUniformly, overflow: .condenseUniformly, minimumSpacing: 10) {

            Box(backgroundColor: .red)
                .constrainedTo(width: 80, height: 80)
                .stackLayoutChild(priority: .fixed)

            Column(alignment: .fill, underflow: .justifyToStart, overflow: .condenseUniformly, minimumSpacing: 10) {

                let rows: [String] = [
                    "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
                ]

                for rowText in rows {
                    Row(alignment: .fill, underflow: .growUniformly, overflow: .condenseUniformly, minimumSpacing: 10) {

                        Box(backgroundColor: .blue)
                            .constrainedTo(width: 40, height: 40)
                            .stackLayoutChild(priority: .fixed)

                        Label(text: rowText)
                            .stackLayoutChild(priority: .flexible)
                    }
                    .stackLayoutChild(priority: .fixed)
                }
            }
            .stackLayoutChild(priority: .flexible)
        }

        let content = Column(alignment: .fill) {
            for _ in 1...10 {
                row
            }
        }

        let size = content.content.measure(in: .init(width: 300))

        let view = BlueprintView()
        view.frame.size = CGSize(width: 300.0, height: size.height)

        view.element = content
        view.layoutIfNeeded()
    }

    func test_rows_with_one_flexible_element() {

        let row = Row(alignment: .fill, underflow: .growUniformly, overflow: .condenseUniformly, minimumSpacing: 10) {

            Box(backgroundColor: .red)
                .constrainedTo(width: 80, height: 80)
                .stackLayoutChild(priority: .fixed)

            Column(alignment: .fill, underflow: .justifyToStart, overflow: .condenseUniformly, minimumSpacing: 10) {

                let rows: [String] = [
                    "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
                    "Fusce dignissim vitae leo sed pretium.",
                    "Morbi molestie, nisl eget faucibus bibendum, magna orci congue ipsum.",
                    "Eu tincidunt orci nunc ac nisl.",
                    "Aenean facilisis nulla vitae nibh suscipit, id placerat est lacinia.",
                ]

                for rowText in rows {
                    Row(alignment: .fill, underflow: .growUniformly, overflow: .condenseUniformly, minimumSpacing: 10) {

                        Box(backgroundColor: .blue)
                            .constrainedTo(width: 40, height: 40)
                            .stackLayoutChild(priority: .fixed)

                        Label(text: rowText)
                            .stackLayoutChild(priority: .flexible)
                    }
                    .stackLayoutChild(priority: .fixed)
                }
            }
            .stackLayoutChild(priority: .flexible)
        }

        let allRows = Column(alignment: .fill) {
            for _ in 1...100 {
                row
            }
        }

        let size = allRows.content.measure(in: .init(width: 300))

        let view = BlueprintView()
        view.frame.size = CGSize(width: 300.0, height: size.height)

        determineAverage(for: 2.0) {
            view.element = allRows
            view.layoutIfNeeded()
        }
    }

    func test_deep_element_hierarchy() {
        let elements = lipsumStrings.map {
            Label(text: $0)
        }

        let stack = Column { col in
            let row = Row { row in
                let col = Column { col in
                    elements.forEach {
                        col.add(child: $0)
                    }
                }

                for _ in 1...10 {
                    row.add(child: col)
                }
            }

            for _ in 1...10 {
                col.add(child: row)
            }
        }

        let view = BlueprintView()
        view.frame.size = CGSize(width: 1000.0, height: 10000)

        determineAverage(for: 10.0) {
            view.element = stack
            view.layoutIfNeeded()
        }
    }

    // Test the performance of deeply nested stacks with leaves that do not have a measurement key.
    func test_deep_stacks() {
        let leafLabelCount = 4
        let stackDepth = 5
        let branchCount = 2
        let runCount = 100

        var labelCount = 0
        func element(depth: Int) -> Element {
            if depth > 0 {
                var stack: StackElement = depth % 2 == 1 ? Row() : Column()

                for _ in 1...branchCount {
                    stack.add(child: element(depth: depth - 1))
                }

                return stack
            } else {
                return Column { column in
                    for string in lipsumStrings[0..<leafLabelCount] {
                        labelCount += 1
                        column.add(child: NonCachingLabel(text: string))
                    }
                }
            }
        }

        let view = BlueprintView()
        view.frame.size = CGSize(width: 1000, height: 10000)

        let tree = element(depth: stackDepth)
        print("layout depth: \(stackDepth) contains \(labelCount) labels")

        for i in 1...runCount {
            print("run \(i) of \(runCount)")
            view.element = tree
            view.layoutIfNeeded()
        }
    }

    func determineAverage(for seconds: TimeInterval, using block: () -> Void) {
        let start = Date()

        var iterations: Int = 0

        repeat {
            let iterationStart = Date()
            block()
            let iterationEnd = Date()
            let duration = iterationEnd.timeIntervalSince(iterationStart)

            iterations += 1

            print("Iteration: \(iterations), Duration : \(duration)")

        } while Date() < start + seconds

        let end = Date()

        let duration = end.timeIntervalSince(start)
        let average = duration / TimeInterval(iterations)

        print("Iterations: \(iterations), Average Time: \(average)")
    }
}


private struct NonCachingLabel: UIViewElement {
    var text: String

    func makeUIView() -> UILabel {
        UILabel()
    }

    func updateUIView(_ view: UILabel, with context: UIViewElementContext) {
        view.numberOfLines = 0
        view.text = text
    }
}

