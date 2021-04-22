import UIKit

/// `StackChild` is a wrapper which allows an element to define its StackLayout traits and Keys.
/// This struct is particularly useful when working with `@StackElementBuilder`.
/// By default, elements will default to a nil key and the default `StackLayout.Traits` initializer.
/// `@StackElementBuilder` will check every child to see if it can be type cast to a `StackChild`
/// and then pull of the given traits and key and then apply those to the stack
public struct StackChild: ProxyElement {
    private let wrapped: Element
    public var traits: StackLayout.Traits
    public var key: AnyHashable?
    
    public struct Sizing {
        public static let fixed: Self = .init(growPriority: 0, shrinkPriority: 0)
        public static let flexible: Self = .init(growPriority: 1, shrinkPriority: 1)

        public var growPriority: CGFloat
        public var shrinkPriority: CGFloat
        
        public init(growPriority: CGFloat = 1, shrinkPriority: CGFloat = 1) {
            self.growPriority = growPriority
            self.shrinkPriority = shrinkPriority
        }
    }

    public init(
        wrappedElement: Element,
        traits: StackLayout.Traits = .init(),
        key: AnyHashable? = nil
    ) {
        self.wrapped = wrappedElement
        self.traits = traits
        self.key = key
    }
    
    public init(
        wrappedElement: Element,
        sizing: Sizing = .flexible,
        alignmentGuide: ((ElementDimensions) -> CGFloat)? = nil,
        key: AnyHashable? = nil
    ) {
        self.init(
            wrappedElement: wrappedElement,
            traits: .init(
                growPriority: sizing.growPriority,
                shrinkPriority: sizing.shrinkPriority,
                alignmentGuide: alignmentGuide.map(StackLayout.AlignmentGuide.init)
            ),
            key: key
        )
    }

    // Simply wraps the given element.
    public var elementRepresentation: Element { wrapped }
}

extension Element {
    
    /// Wraps an element with a `StackChild` in order to customize `StackLayout.Traits` and the key.
    /// - Parameters:
    ///   - sizing: Controls the amount of extra space distributed to this child during underflow and overflow
    ///   - alignmentGuide: Allows for custom alignment of a child along the cross axis.
    ///   - key: A key used to disambiguate children between subsequent updates of the view
    ///     hierarchy.
    /// - Returns: A wrapped element with additional layout information for the `StackElement`.
    public func stackChild(
        sizing: StackChild.Sizing = .flexible,
        alignmentGuide: ((ElementDimensions) -> CGFloat)? = nil,
        key: AnyHashable? = nil
    ) -> StackChild {
        .init(
            wrappedElement: self,
            sizing: sizing,
            alignmentGuide: alignmentGuide, key: key
        )
    }
    
    /// Wraps an element with a `StackChild` in order to customize `StackLayout.Traits` and the key.
    /// - Parameters:
    ///   - traits: Contains traits that affect the layout of individual children in the stack.
    ///   - key: A key used to disambiguate children between subsequent updates of the view
    ///     hierarchy.
    /// - Returns: A wrapped element with additional layout information for the `StackElement`.
    public func stackChild(traits: StackLayout.Traits = .init(), key: AnyHashable? = nil) -> StackChild {
        .init(wrappedElement: self, traits: traits, key: key)
    }
}
