//
//  ElementProperty.swift
//  Pods
//
//  Created by Kyle Van Essen on 9/4/22.
//

import Foundation


@propertyWrapper public struct ElementProperty: Equatable {

    public var wrappedValue: Element

    public init(wrappedValue: Element) {
        self.wrappedValue = wrappedValue
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {

        guard let lhs = lhs as? AnyComparableElement else { return false }
        guard let rhs = rhs as? AnyComparableElement else { return false }

        return lhs.anyIsEquivalent(to: rhs)
    }
}


@propertyWrapper public struct OptionalElementProperty: Equatable {

    public var wrappedValue: Element?

    public init(wrappedValue: Element?) {
        self.wrappedValue = wrappedValue
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {

        guard let lhs = lhs as? AnyComparableElement else { return false }
        guard let rhs = rhs as? AnyComparableElement else { return false }

        return lhs.anyIsEquivalent(to: rhs) // TODO: kill off the try!
    }
}
