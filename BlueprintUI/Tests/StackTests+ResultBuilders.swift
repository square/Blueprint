import XCTest
@testable import BlueprintUI

class StackTestsResultBuilders: XCTestCase {
    func test_resultBuilder_column() {
        let column = Column {
            TestElement()
            TestElement2().stackLayoutChild(priority: .fixed, alignmentGuide: { _ in 0 }, key: "two")
            TestElement2().keyed("three")
        }

        let child1 = column.children[0]
        XCTAssert(type(of: child1.element) == TestElement.self)
        XCTAssertEqual(child1.traits.growPriority, 1)
        XCTAssertEqual(child1.traits.shrinkPriority, 1)
        XCTAssertNil(child1.traits.alignmentGuide)
        XCTAssertNil(child1.key)

        let child2 = column.children[1]
        XCTAssert(type(of: child2.element) == TestElement2.self)
        XCTAssertEqual(child2.traits.growPriority, 0)
        XCTAssertEqual(child2.traits.shrinkPriority, 0)
        XCTAssertNotNil(child2.traits.alignmentGuide)
        XCTAssertEqual(child2.key, "two")

        let child3 = column.children[2]
        XCTAssert(type(of: child3.element) == TestElement2.self)
        XCTAssertEqual(child3.key, "three")
    }

    func test_resultBuilder_row() {
        let row = Row {
            TestElement()
            TestElement2().stackLayoutChild(priority: .fixed, alignmentGuide: { _ in 0 }, key: "two")
        }

        let child1 = row.children[0]
        XCTAssert(type(of: child1.element) == TestElement.self)
        XCTAssertEqual(child1.traits.growPriority, 1)
        XCTAssertEqual(child1.traits.shrinkPriority, 1)
        XCTAssertNil(child1.traits.alignmentGuide)
        XCTAssertNil(child1.key)

        let child2 = row.children[1]
        XCTAssert(type(of: child2.element) == TestElement2.self)
        XCTAssertEqual(child2.traits.growPriority, 0)
        XCTAssertEqual(child2.traits.shrinkPriority, 0)
        XCTAssertNotNil(child2.traits.alignmentGuide)
        XCTAssertEqual(child2.key, "two")

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



fileprivate struct TestElement2: Element {

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
