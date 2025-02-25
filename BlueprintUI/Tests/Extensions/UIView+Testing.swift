import UIKit
import XCTest

extension UIView {
    /// Does a breadth-first search for a subview of the given type, optionally matching a
    /// predicate.
    public func findSubview<View: UIView>(
        ofType viewType: View.Type,
        where predicate: (View) -> Bool = { _ in true }
    ) -> View? {
        for subview in subviews {
            if let match = subview as? View, predicate(match) {
                return match
            }
        }

        for view in subviews {
            if let match = view.findSubview(ofType: viewType, where: predicate) {
                return match
            }
        }

        return nil
    }

    public func expectedChild<T: UIView>(ofType viewType: T.Type) throws -> T {
        try XCTUnwrap(
            findSubview(ofType: viewType),
            "Expected to find child of type \(T.self) but no child was found"
        )
    }
}
