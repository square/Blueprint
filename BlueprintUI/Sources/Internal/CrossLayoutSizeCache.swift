import UIKit

@MainActor
final class CrossLayoutSizeCache: Sendable {

    private var state: [Key: CGSize] = [:]
    typealias ElementCache = (CGRect, Environment, LayoutMode) -> CGSize?

    subscript(key: Key) -> CGSize? {
        get {
            state[key]
        }
        set {
            state[key] = newValue
        }
    }

    func elementCache(for element: Element) -> ElementCache? {
        { [weak self] frame, environment, layoutMode -> CGSize? in
            self?.state[Key(element: element, frame: frame, environment: environment, layoutMode: layoutMode)]
        }
    }

}

extension CrossLayoutSizeCache {

    struct Key: Hashable {

        let element: Element
        let frame: CGRect
        let environment: Environment
        let layoutMode: LayoutMode

        // FIXME: REMOVE
        func hash(into hasher: inout Hasher) {
            frame.hash(into: &hasher)
            layoutMode.hash(into: &hasher)
        }

        // FIXME: REMOVE
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.frame == rhs.frame &&
                lhs.layoutMode == rhs.layoutMode
        }


    }

}
