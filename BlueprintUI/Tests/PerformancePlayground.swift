//
//  PerformancePlayground.swift
//  BlueprintUI-Unit-Tests
//
//  Created by Kyle Van Essen on 6/23/20.
//

import XCTest
@testable import BlueprintUI


class PerformancePlayground : XCTestCase
{
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
        // super.invokeTest()
    }
    
    func test_repeated_layouts()
    {
        let element = Column { col in
            for index in 1...1000 {
                col.add(child: TestLabel(text: "This is test label number #\(index)"))
            }
        }
        
        let view = BlueprintView(frame: CGRect(x: 0.0, y: 0.0, width: 200.0, height: 500.0))
        
        self.determineAverage(for: 10.0) {
            view.element = element
            view.layoutIfNeeded()
        }
    }
    
    func test_deep_element_hierarchy()
    {
        let elements = lipsumStrings.map(TestLabel.init)

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
                
        self.determineAverage(for: 10.0) {
            view.element = stack
            view.layoutIfNeeded()
        }
    }

    // Test the performance of deeply nested stacks with leaves that do not have a measurement key.
    func test_deep_stacks() {
        let leafLabelCount = 4
        let stackDepth = 5
        let branchCount = 2
        let runCount = 1

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
    
    func determineAverage(for seconds : TimeInterval, using block : () -> ()) {
        let start = Date()
        
        var iterations : Int = 0
        
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

    static func makeUIView() -> UILabel {
        UILabel()
    }

    func updateUIView(_ view: UILabel, with context: UIViewElementContext) {
        view.numberOfLines = 0
        view.text = text
    }
}

fileprivate struct TestLabel : UIViewElement
{
    var text : String
    
    // MARK: UIViewElement
    
    typealias UIViewType = UILabel
    
    static func makeUIView() ->  UILabel {
        UILabel()
    }
    
    var measurementCacheKey: AnyHashable? {
        self.text
    }
    
    func updateUIView(_ view:  UILabel, with context: UIViewElementContext) {
        view.numberOfLines = 0
        view.text = self.text
    }
}
