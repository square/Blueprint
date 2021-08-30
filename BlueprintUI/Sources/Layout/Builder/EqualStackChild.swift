import UIKit

/// `EqualStackChild` is a wrapper which allows an element to define its StackLayout traits and Keys.
/// This struct is particularly useful when working with `@ElementBuilder`.
/// By default, elements will default to a nil key and the default `StackLayout.Traits` initializer.
/// `@StackElementBuilder` will check every child to see if it can be type cast to a `StackChild`
/// and then pull of the given traits and key and then apply those to the stack
public struct EqualStackChild {
    public let element: Element

    public init(element: Element) {
        self.element = element
    }
}

extension Element {
    
    /// Wraps an element with a `StackChild` in order to customize `StackLayout.Traits` and the key.
    /// - Parameters:
    /// - Returns: A wrapped element with additional layout information for the `EqualStackElement`.
    public func equalStackChild() -> EqualStackChild {
        .init(element: self)
    }
}


extension EqualStackChild: ElementInitializable {
    public init(from element: Element) {
        self = element.equalStackChild()
    }
}
