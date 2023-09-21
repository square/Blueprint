import XCTest
@testable import BlueprintUI

extension LayoutResultNode {
    func findLayout(of elementType: Element.Type) -> LayoutResultNode? {
        if type(of: element) == elementType {
            return self
        }

        for child in children {
            if let node = child.node.findLayout(of: elementType) {
                return node
            }
        }
        return nil
    }

    func queryLayout(for elementType: Element.Type) -> [LayoutResultNode] {
        var results: [LayoutResultNode] = []

        if type(of: element) == elementType {
            results.append(self)
        }

        for child in children {
            results.append(contentsOf: child.node.queryLayout(for: elementType))
        }

        return results
    }
}
