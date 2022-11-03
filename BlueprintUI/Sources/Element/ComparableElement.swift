//
//  ComparableElement.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 7/3/21.
//

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
    /// Return true if the elements are the same, or return false if something about
    /// the element changed, such as attributes that affect measurement or layout.
    ///
    /// Note that even if this method returns true, the `ViewDescription`
    /// backing the element will still be re-applied to the on-screen view.
    ///
    /// A `ComparableElementContext` parameter is provided, in case
    /// you need access to the `Environment`, etc, to perform your comparison.
    /// This is useful, for example, if your `Element` contains builders that are used to
    /// build the final element structure.
    ///
    /// If your element conforms to `Equatable`, this method is synthesized automatically.
    ///
    func isEquivalent(to other: Self, in context: ComparableElementContext) -> Bool
}


/// A context object pased to `isEquivalent(to:in:)` that contains
/// contextual information in which the `Element` is being compared. This
/// is useful, for example, if you need information from the `Environment`
/// to perform the comparison.
public struct ComparableElementContext {

    /// The `Environment` in which the comparison is being performed.
    public var environment: Environment

    /// Creates a new context object.
    public init(
        environment: Environment
    ) {
        self.environment = environment
    }
}


/// Provides a default `ComparableElement` implementation for `Equatable` elements.
extension ComparableElement where Self: Equatable {

    public func isEquivalent(to other: Self, in context: ComparableElementContext) -> Bool {
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
    func anyIsEquivalent(to other: AnyComparableElement, in context: ComparableElementContext) -> Bool
}


extension ComparableElement {

    public func anyIsEquivalent(to other: AnyComparableElement, in context: ComparableElementContext) -> Bool {
        guard let other = other as? Self else { return false }

        return isEquivalent(to: other, in: context)
    }
}
