import XCTest
@testable import BlueprintUI


class ElementIdentifierTests: XCTestCase {

    func test_equality() {

        // Equal
        
        XCTAssertEqual(
            ElementIdentifier(elementType: A.self, key: nil, count: 0),
            ElementIdentifier(elementType: A.self, key: nil, count: 0)
        )
        
        XCTAssertEqual(
            ElementIdentifier(elementType: A.self, key: "aKey", count: 0),
            ElementIdentifier(elementType: A.self, key: "aKey", count: 0)
        )
        
        // Not Equal
        
        XCTAssertNotEqual(
            ElementIdentifier(elementType: A.self, key: nil, count: 0),
            ElementIdentifier(elementType: B.self, key: nil, count: 0)
        )
        
        XCTAssertNotEqual(
            ElementIdentifier(elementType: A.self, key: nil, count: 0),
            ElementIdentifier(elementType: A.self, key: nil, count: 1)
        )
        
        XCTAssertNotEqual(
            ElementIdentifier(elementType: A.self, key: nil, count: 0),
            ElementIdentifier(elementType: A.self, key: "aKey", count: 0)
        )
    }
}


class ElementIdentifier_FactoryTests : XCTestCase
{
    func test_factory()
    {
        var factory = ElementIdentifier.Factory()
        
        let identifierA1 = factory.nextIdentifier(for: A.self, key: nil)
        let identifierA2 = factory.nextIdentifier(for: A.self, key: nil)
        let identifierA3 = factory.nextIdentifier(for: A.self, key: "aKey")
        let identifierA4 = factory.nextIdentifier(for: A.self, key: "aKey")
        
        let identifierB1 = factory.nextIdentifier(for: B.self, key: nil)
        let identifierB2 = factory.nextIdentifier(for: B.self, key: nil)
        let identifierB3 = factory.nextIdentifier(for: B.self, key: "aKey")
        let identifierB4 = factory.nextIdentifier(for: B.self, key: "aKey")
        
        XCTAssertEqual(identifierA1, ElementIdentifier(elementType: A.self, key: nil, count: 1))
        XCTAssertEqual(identifierA2, ElementIdentifier(elementType: A.self, key: nil, count: 2))
        XCTAssertEqual(identifierA3, ElementIdentifier(elementType: A.self, key: "aKey", count: 1))
        XCTAssertEqual(identifierA4, ElementIdentifier(elementType: A.self, key: "aKey", count: 2))
        
        XCTAssertEqual(identifierB1, ElementIdentifier(elementType: B.self, key: nil, count: 1))
        XCTAssertEqual(identifierB2, ElementIdentifier(elementType: B.self, key: nil, count: 2))
        XCTAssertEqual(identifierB3, ElementIdentifier(elementType: B.self, key: "aKey", count: 1))
        XCTAssertEqual(identifierB4, ElementIdentifier(elementType: B.self, key: "aKey", count: 2))
    }
}


fileprivate struct A: Element {

    var content: ElementContent {
        return ElementContent(intrinsicSize: .zero)
    }

    func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return nil
    }

}

fileprivate struct B: Element {

    var content: ElementContent {
        return ElementContent(intrinsicSize: .zero)
    }

    func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return nil
    }
    
}
