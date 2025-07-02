import UIKit

// TODO: COW struct?
final class CrossLayoutSizeCache: Sendable {

    private var state: [String: (Environment, CGSize)] = [:]

    subscript(elementPath: String) -> (Environment, CGSize)? {
        get {
            state[elementPath]
        }
        set {
            state[elementPath] = newValue
        }
    }

}
