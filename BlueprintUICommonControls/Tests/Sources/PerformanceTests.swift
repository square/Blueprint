//
//  PerformanceTests.swift
//  BlueprintUI-Unit-Tests
//
//  Created by Kyle Van Essen on 6/23/20.
//

import XCTest
import BlueprintUI
@testable import BlueprintUICommonControls


class PerformanceTests : XCTestCase
{
    override func invokeTest() {
        // Uncomment this line to run performance metrics, eg in Instruments.app.
        super.invokeTest()
    }
    
//    func test_deep_proxy_elements() {
//
//    }
    
    func test_deep_element_hierarchy() {
                
        let view = BlueprintView(frame: CGRect(x: 0.0, y: 0.0, width: 1000, height: 10000))
                
        self.determineAverage {
            let elements = [
                Label(text: "Lorem ipsum dolor sit amet, consectetur adipiscing elit."),
                Label(text: "Integer molestie et felis at sodales."),
                Label(text: "Donec varius, orci vel suscipit hendrerit, risus massa ornare dui, at gravida elit sapien at lorem."),
                Label(text: "Nunc in ipsum porttitor, tincidunt est eu, euismod odio."),
                Label(text: "Duis posuere nunc sed mi auctor, in dictum elit iaculis."),
                Label(text: "Ut vel varius est. Duis efficitur vel lorem quis tempor."),
                Label(text: "Nulla porttitor, mi nec posuere bibendum, turpis ipsum ultrices tortor, a placerat sapien augue quis sem."),
                Label(text: "Cras volutpat nisl vitae elit convallis, quis tempor massa faucibus."),
            ]
            
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
            
            view.element = stack
            view.layoutIfNeeded()
        }
    }
    
    func test_repeated_layouts() {
        
        let view = BlueprintView(frame: CGRect(x: 0.0, y: 0.0, width: 200.0, height: 500.0))
        
        self.determineAverage {
            let element = Column { col in
                for index in 1...1000 {
                    col.add(child: Label(text: "This is test label number #\(index)"))
                }
            }
            
            
            view.element = element
            view.layoutIfNeeded()
        }
    }
}


extension XCTestCase {
    func determineAverage(for seconds : TimeInterval = 10.0, using block : () -> ()) {
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
