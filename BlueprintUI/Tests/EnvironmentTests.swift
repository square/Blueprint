import XCTest
@testable import BlueprintUI


class EnvironmentTests: XCTestCase {

    func test_default() {
        let testValue = TestValue.defaultValue
        let element = AdaptingElement()

        let view = TestView()
        let size = element.content.measure(in: .unconstrained, environment: .empty)
        let layoutResultNode = element.layout(frame: .zero)

        let attributes = leafAttributes(in: element.layout(frame: .zero))
        let viewDescription = leafViewDescription(
            in: NativeViewNode(
                content: UIView.describe { _ in },
                layoutAttributes: LayoutAttributes(frame: .zero),
                children: layoutResultNode.resolve()))

        viewDescription.apply(to: view)

        XCTAssertEqual(size, testValue.size)
        XCTAssertEqual(attributes, testValue.layoutAttributes)
        XCTAssertEqual(view.testValue, testValue)
    }

    func test_adapted() {
        let testValue = TestValue.right
        let element = AdaptedEnvironment(
            key: TestKey.self,
            value: testValue,
            wrapping: AdaptingElement())

        let view = TestView()
        let size = element.content.measure(in: .unconstrained, environment: .empty)
        let layoutResultNode = element.layout(frame: .zero)

        let attributes = leafAttributes(in: element.layout(frame: .zero))
        let viewDescription = leafViewDescription(
            in: NativeViewNode(
                content: UIView.describe { _ in },
                layoutAttributes: LayoutAttributes(frame: .zero),
                children: layoutResultNode.resolve()))

        viewDescription.apply(to: view)

        XCTAssertEqual(size, testValue.size)
        XCTAssertEqual(attributes, testValue.layoutAttributes)
        XCTAssertEqual(view.testValue, testValue)
    }

    func test_nestedAdapter() {
        let testValue = TestValue.right
        let element = AdaptedEnvironment(
            key: TestKey.self,
            value: .wrong,
            wrapping: AdaptedEnvironment(
                key: TestKey.self,
                value: testValue,
                wrapping: AdaptingElement()))

        let view = TestView()
        let size = element.content.measure(in: .unconstrained, environment: .empty)
        let layoutResultNode = element.layout(frame: .zero)

        let attributes = leafAttributes(in: element.layout(frame: .zero))
        let viewDescription = leafViewDescription(
            in: NativeViewNode(
                content: UIView.describe { _ in },
                layoutAttributes: LayoutAttributes(frame: .zero),
                children: layoutResultNode.resolve()))

        viewDescription.apply(to: view)

        XCTAssertEqual(size, testValue.size)
        XCTAssertEqual(attributes, testValue.layoutAttributes)
        XCTAssertEqual(view.testValue, testValue)
    }

    func leafAttributes(in node: LayoutResultNode) -> LayoutAttributes {
        if let childNode = node.children.first?.node {
            return leafAttributes(in: childNode)
        }
        return node.layoutAttributes
    }

    func leafViewDescription(in node: NativeViewNode) -> ViewDescription {
        if let child = node.children.first?.node {
            return leafViewDescription(in: child)
        }
        return node.viewDescription
    }

    struct AdaptingElement: ProxyElement {
        var elementRepresentation: Element {
            return EnvironmentReader { environment -> Element in
                return TestElement(value: environment.testValue)
            }
        }
    }
}

/// A view-backed element with one child, whose measurement, layout, and view description varies
/// based on the passed in test value.
private struct TestElement: Element {
    var value: TestValue

    var content: ElementContent {
        return ElementContent(
            layout: TestLayout(value: value),
            configure: { (layout) in
                layout.add(element: Spacer(size: CGSize(width: 8, height: 8)))
            })
    }

    struct TestLayout: Layout {
        var value: TestValue

        func measure(in constraint: SizeConstraint, items: [(traits: (), content: Measurable)]) -> CGSize {
            return value.size
        }

        func layout(size: CGSize, items: [(traits: (), content: Measurable)]) -> [LayoutAttributes] {
            return [value.layoutAttributes]
        }
    }

    func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return TestView.describe { config in
            config[\.testValue] = self.value
        }
    }
}

private class TestView: UIView {
    var testValue = TestValue.defaultValue
}

private enum TestValue {
    case defaultValue
    case wrong
    case right

    var size: CGSize {
        switch self {
        case .defaultValue:
            return CGSize(width: 2, height: 3)
        case .right:
            return CGSize(width: 4, height: 5)
        case .wrong:
            return CGSize(width: 6, height: 7)
        }
    }

    var layoutAttributes: LayoutAttributes {
        return LayoutAttributes(size: size)
    }
}

private enum TestKey: EnvironmentKey {
    static let defaultValue = TestValue.defaultValue
}

private extension Environment {
    var testValue: TestValue  {
        get { return self[TestKey.self] }
        set { self[TestKey.self] = newValue }
    }
}
