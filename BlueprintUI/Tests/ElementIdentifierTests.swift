import XCTest
@testable import BlueprintUI


class ElementIdentifierTests: XCTestCase {

    func test_equality() {

        // Equal

        XCTAssertEqual(
            ElementIdentifier.identifier(for: A(), key: nil, count: 0),
            ElementIdentifier.identifier(for: A(), key: nil, count: 0)
        )

        XCTAssertEqual(
            ElementIdentifier.identifier(for: A(), key: "aKey", count: 0),
            ElementIdentifier.identifier(for: A(), key: "aKey", count: 0)
        )

        // Not Equal

        XCTAssertNotEqual(
            ElementIdentifier.identifier(for: A(), key: nil, count: 0),
            ElementIdentifier.identifier(for: B(), key: nil, count: 0)
        )

        XCTAssertNotEqual(
            ElementIdentifier.identifier(for: A(), key: nil, count: 0),
            ElementIdentifier.identifier(for: A(), key: nil, count: 1)
        )

        XCTAssertNotEqual(
            ElementIdentifier.identifier(for: A(), key: nil, count: 0),
            ElementIdentifier.identifier(for: A(), key: "aKey", count: 0)
        )
    }

    func test_elementIdentifierCaching() {
        let id1 = ElementIdentifier.identifier(for: A(), key: nil, count: 0)
        let id2 = ElementIdentifier.identifier(for: B(), key: nil, count: 0)
        let id3 = ElementIdentifier.identifier(for: A(), key: "unique", count: 0)
        let id4 = ElementIdentifier.identifier(for: A(), key: nil, count: 1)
        let id5 = ElementIdentifier.identifier(for: A(), key: nil, count: 0)
        let id6 = ElementIdentifier.identifier(for: B(), key: nil, count: 0)

        var set = Set([id1.objectIdentifier])
        XCTAssertFalse(set.contains(id2.objectIdentifier))
        set.insert(id2.objectIdentifier)
        XCTAssertFalse(set.contains(id3.objectIdentifier))
        set.insert(id3.objectIdentifier)
        XCTAssertFalse(set.contains(id4.objectIdentifier))
        set.insert(id4.objectIdentifier)
        XCTAssertTrue(set.contains(id5.objectIdentifier))
        set.insert(id5.objectIdentifier)
        XCTAssertTrue(set.contains(id6.objectIdentifier))

        XCTAssertEqual(id1.objectIdentifier, id5.objectIdentifier)
        XCTAssertEqual(id2.objectIdentifier, id6.objectIdentifier)
        XCTAssertNotEqual(id5.objectIdentifier, id6.objectIdentifier)
    }
}


class ElementIdentifier_FactoryTests: XCTestCase {
    func test_factory() {
        var factory = ElementIdentifier.Factory(elementCount: 10)

        let identifierA1 = factory.nextIdentifier(for: A(), key: nil)
        let identifierA2 = factory.nextIdentifier(for: A(), key: nil)
        let identifierA3 = factory.nextIdentifier(for: A(), key: "aKey")
        let identifierA4 = factory.nextIdentifier(for: A(), key: "aKey")

        let identifierB1 = factory.nextIdentifier(for: B(), key: nil)
        let identifierB2 = factory.nextIdentifier(for: B(), key: nil)
        let identifierB3 = factory.nextIdentifier(for: B(), key: "aKey")
        let identifierB4 = factory.nextIdentifier(for: B(), key: "aKey")

        XCTAssertEqual(identifierA1, ElementIdentifier.identifier(for: A(), key: nil, count: 1))
        XCTAssertEqual(identifierA2, ElementIdentifier.identifier(for: A(), key: nil, count: 2))
        XCTAssertEqual(identifierA3, ElementIdentifier.identifier(for: A(), key: "aKey", count: 1))
        XCTAssertEqual(identifierA4, ElementIdentifier.identifier(for: A(), key: "aKey", count: 2))

        XCTAssertEqual(identifierB1, ElementIdentifier.identifier(for: B(), key: nil, count: 1))
        XCTAssertEqual(identifierB2, ElementIdentifier.identifier(for: B(), key: nil, count: 2))
        XCTAssertEqual(identifierB3, ElementIdentifier.identifier(for: B(), key: "aKey", count: 1))
        XCTAssertEqual(identifierB4, ElementIdentifier.identifier(for: B(), key: "aKey", count: 2))
    }
}


fileprivate struct A: Element {

    var content: ElementContent {
        ElementContent(intrinsicSize: .zero)
    }

    func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        nil
    }

}

fileprivate struct B: Element {

    var content: ElementContent {
        ElementContent(intrinsicSize: .zero)
    }

    func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        nil
    }

}

extension ElementIdentifier {
    var objectIdentifier: ObjectIdentifier {
        .init(self)
    }
}
