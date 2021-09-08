import UIKit


/// `StackChild` is a wrapper which holds an element along with  its StackLayout traits and Keys.
/// This struct is particularly useful when working with `@ElementBuilder<StackChild>`.
/// By default, elements inside of `ElementBuilder<StackChild>` will be implicitly converted to a StackChild
/// with a nil key and the default `StackLayout.Traits` initializer. But when given a `StackChild` via
/// `Element.stackChild(...)` modifier or initialized directly, `@ElementBuilder<StackChild>`
/// pull out the given traits and key and then apply those to the stack
public struct StackChild {
    public let element: Element
    public let traits: StackLayout.Traits
    public let key: AnyHashable?

    public enum Priority {
        case fixed
        case flexible
        case grows
        case shrinks

        fileprivate var growPriority: CGFloat {
            switch self {
            case .fixed: return 0
            case .flexible: return 1
            case .grows: return 1
            case .shrinks: return 0
            }
        }

        fileprivate var shrinkPriority: CGFloat {
            switch self {
            case .fixed: return 0
            case .flexible: return 1
            case .grows: return 0
            case .shrinks: return 1
            }
        }
    }

    public init(
        element: Element,
        traits: StackLayout.Traits = .init(),
        key: AnyHashable? = nil
    ) {
        self.element = element
        self.traits = traits
        self.key = key
    }

    public init(
        element: Element,
        priority: Priority = .flexible,
        alignmentGuide: ((ElementDimensions) -> CGFloat)? = nil,
        key: AnyHashable? = nil
    ) {
        self.init(
            element: element,
            traits: .init(
                growPriority: priority.growPriority,
                shrinkPriority: priority.shrinkPriority,
                alignmentGuide: alignmentGuide.map(StackLayout.AlignmentGuide.init)
            ),
            key: key
        )
    }
}


extension Element {

    /// Wraps an element with a `StackChild` in order to customize `StackLayout.Traits` and the key.
    /// - Parameters:
    ///   - sizing: Controls the amount of extra space distributed to this child during underflow and overflow
    ///   - alignmentGuide: Allows for custom alignment of a child along the cross axis.
    ///   - key: A key used to disambiguate children between subsequent updates of the view
    ///     hierarchy.
    /// - Returns: A wrapper containing this element with additional layout information for the `StackElement`.
    public func stackChild(
        priority: StackChild.Priority = .flexible,
        alignmentGuide: ((ElementDimensions) -> CGFloat)? = nil,
        key: AnyHashable? = nil
    ) -> StackChild {
        .init(
            element: self,
            priority: priority,
            alignmentGuide: alignmentGuide,
            key: key
        )
    }

    /// Wraps an element with a `StackChild` in order to customize `StackLayout.Traits` and the key.
    /// - Parameters:
    ///   - traits: Contains traits that affect the layout of individual children in the stack.
    ///   - key: A key used to disambiguate children between subsequent updates of the view
    ///     hierarchy.
    /// - Returns: A wrapper containing this element with additional layout information for the `StackElement`.
    public func stackChild(traits: StackLayout.Traits = .init(), key: AnyHashable? = nil) -> StackChild {
        .init(element: self, traits: traits, key: key)
    }
}


extension StackChild: ElementBuilderChild {
    public init(_ element: Element) {
        self.init(element: element)
    }
}
