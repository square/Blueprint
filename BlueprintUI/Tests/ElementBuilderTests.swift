import BlueprintUI
import XCTest

class ElementBuilderTests: XCTestCase {
    func test_resultBuilder_conditional() {
        let condition: Bool = .random()
        let gridRow = GridRow {

            if condition {
                TestElement()
            }

            if !condition {
                TestElement2()
            }
        }

        XCTAssertEqual(gridRow.children.count, 1)
        if condition {
            XCTAssert(type(of: gridRow.children[0].element) == TestElement.self)
        } else {
            XCTAssert(type(of: gridRow.children[0].element) == TestElement2.self)
        }
    }

    func test_resultBuilder_ternary() {
        let condition: Bool = .random()
        let gridRow = GridRow {
            condition ? TestElement() : TestElement2()
        }

        XCTAssertEqual(gridRow.children.count, 1)
        if condition {
            XCTAssert(type(of: gridRow.children[0].element) == TestElement.self)
        } else {
            XCTAssert(type(of: gridRow.children[0].element) == TestElement2.self)
        }
    }

    func test_resultBuilder_optional() {
        let condition: Bool = .random()

        func optionalElement1() -> Element? {
            condition ? TestElement() : nil
        }

        func optionalElement2() -> Element? {
            !condition ? TestElement2() : nil
        }

        let gridRow = GridRow {
            optionalElement1()
            optionalElement2()
        }

        XCTAssertEqual(gridRow.children.count, 1)
        if condition {
            XCTAssert(type(of: gridRow.children[0].element) == TestElement.self)
        } else {
            XCTAssert(type(of: gridRow.children[0].element) == TestElement2.self)
        }
    }

    func test_resultBuilder_optional_expression() {
        enum TestEnum: CaseIterable {
            case first
            case second
            case third
        }

        let item = TestEnum.first

        let gridRow = GridRow {
            switch item {
            case .first:
                TestElement()
            case .second:
                nil
            case .third:
                nil
            }

            switch item {
            case .first:
                nil
            case .second:
                TestElement()
            case .third:
                nil
            }
        }

        XCTAssertEqual(gridRow.children.count, 1)
    }

    func test_resultBuilder_either_ifelse() {
        let condition: Bool = .random()
        let gridRow = GridRow {

            if condition {
                TestElement()
            } else {
                TestElement2()
            }
        }

        XCTAssertEqual(gridRow.children.count, 1)
        if condition {
            XCTAssert(type(of: gridRow.children[0].element) == TestElement.self)
        } else {
            XCTAssert(type(of: gridRow.children[0].element) == TestElement2.self)
        }
    }

    func test_resultBuilder_either_ifelseif() {
        let condition1: Bool = .random()
        let condition2: Bool = .random()
        let gridRow = GridRow {
            if condition1 {
                TestElement()
            } else if condition2 {
                TestElement2()
            } else {
                TestElement3()
            }
        }
        XCTAssertEqual(gridRow.children.count, 1)
        if condition1 {
            XCTAssert(type(of: gridRow.children[0].element) == TestElement.self)
        } else if condition2 {
            XCTAssert(type(of: gridRow.children[0].element) == TestElement2.self)
        } else {
            XCTAssert(type(of: gridRow.children[0].element) == TestElement3.self)
        }
    }

    func test_resultBuilder_either_switch() {
        enum Condition: CaseIterable {
            case condition1, condition2, condition3
        }

        let condition = Condition.allCases.randomElement() ?? .condition1
        let gridRow = GridRow {
            switch condition {
            case .condition1:
                TestElement()
            case .condition2:
                TestElement2()
            case .condition3:
                TestElement3()
            }
        }
        XCTAssertEqual(gridRow.children.count, 1)
        switch condition {
        case .condition1:
            XCTAssert(type(of: gridRow.children[0].element) == TestElement.self)
        case .condition2:
            XCTAssert(type(of: gridRow.children[0].element) == TestElement2.self)
        case .condition3:
            XCTAssert(type(of: gridRow.children[0].element) == TestElement3.self)
        }
    }

    func test_resultBuilder_for_loop() {

        let gridRow = GridRow {
            for _ in 1...3 {
                TestElement()
            }
        }

        XCTAssertEqual(gridRow.children.count, 3)
    }

    func test_resultBuilder_available() {

        let gridRow = GridRow {
            if #available(iOS 30.0, *) {
                TestElement()
            } else {
                TestElement2()
            }

            if #available(iOS 14.0, *) {
                TestElement3()
            }
        }

        XCTAssertEqual(gridRow.children.count, 2)

        XCTAssert(type(of: gridRow.children[0].element) == TestElement2.self)
        XCTAssert(type(of: gridRow.children[1].element) == TestElement3.self)
    }

    func test_optional() {
        let optionalElementNil: TestElement? = nil
        let optionalElement: TestElement? = TestElement()

        let gridRow = GridRow {
            if let optionalElement = optionalElement {
                optionalElement
            }

            if let optionalElementNil = optionalElementNil {
                optionalElementNil
            }

            optionalElement
            optionalElementNil

            optionalElement.map { _ in TestElement2() }
            optionalElementNil.map { _ in TestElement3() }
        }

        XCTAssertEqual(gridRow.children.count, 3)

        XCTAssert(type(of: gridRow.children[0].element) == TestElement.self)
        XCTAssert(type(of: gridRow.children[1].element) == TestElement.self)
        XCTAssert(type(of: gridRow.children[2].element) == TestElement2.self)
    }
}

private struct TestElement: Element {
    var size: CGSize

    init(size: CGSize = .zero) {
        self.size = size
    }

    var content: ElementContent {
        ElementContent(intrinsicSize: size)
    }

    func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        nil
    }
}


private struct TestElement2: Element {
    var size: CGSize

    init(size: CGSize = .zero) {
        self.size = size
    }

    var content: ElementContent {
        ElementContent(intrinsicSize: size)
    }

    func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        nil
    }
}

private struct TestElement3: Element {
    var size: CGSize

    init(size: CGSize = .zero) {
        self.size = size
    }

    var content: ElementContent {
        ElementContent(intrinsicSize: size)
    }

    func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        nil
    }
}
