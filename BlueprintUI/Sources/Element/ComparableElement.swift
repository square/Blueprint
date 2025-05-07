import Foundation
import UIKit


/// An `ComparableElement` is an element which can cache its
/// measurements and layouts across layout passes in order to dramatically improve
/// performance of repeated layouts.
///
/// Some element types within Blueprint already conform to `ComparableElement`.
/// If your element can be easily compared for equality, consider making your
/// it conform to `ComparableElement` for improved performance across layouts.
public protocol ComparableElement: AnyComparableElement {

    ///
    /// Indicates if the element is equivalent to the other provided element.
    /// Return `true` if the elements are the same, or return `false` if something about
    /// the element changed that will affect measurement or layout.
    ///
    /// ## Note
    /// Even if this method returns true, the `ViewDescription`
    /// backing the element will still be re-applied to the on-screen view.
    ///
    /// ## Equatable
    /// If your element conforms to `Equatable`, this method is synthesized automatically.
    ///
    func isEquivalent(to other: Self) -> Bool
}


/// Provides a default `ComparableElement` implementation for `Equatable` elements.
extension ComparableElement where Self: Equatable {

    public func isEquivalent(to other: Self) -> Bool {
        self == other
    }
}


/// A type-erased version of `ComparableElement`, allowing the comparison
/// of two arbitrary elements, and allowing direct access to methods, without self or associated type constraints.
///
/// ## Note
/// You do not need to implement this protocol yourself. It is implemented by Blueprint on `ComparableElement`.
public protocol AnyComparableElement: Element {

    /// Returns true if the two elements are the same type, and are equivalent.
    func anyIsEquivalent(to other: AnyComparableElement) -> Bool
}


extension ComparableElement {

    public func anyIsEquivalent(to other: AnyComparableElement) -> Bool {
        guard let other = other as? Self else { return false }

        return isEquivalent(to: other)
    }
}
