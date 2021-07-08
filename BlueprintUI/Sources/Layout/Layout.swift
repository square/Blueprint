import UIKit

/// Conforming types can calculate layout attributes for an array of children.
public protocol Layout {
    
    /// Per-item metadata that is used during the measuring and layout pass.
    associatedtype Traits = ()

    /// Computes the size that this layout requires in a layout, given an array
    /// of chidren and accompanying layout traits.
    ///
    /// - parameter constraint: The size constraint in which measuring should
    ///   occur.
    /// - parameter items: An array of 'items', pairs consisting of a traits
    ///   object and a `Measurable` value.
    ///
    /// - returns: The measured size for the given array of items.
    func measure(
        items: LayoutItems<Self.Traits>,
        in constraint : SizeConstraint,
        with context: LayoutContext
    ) -> CGSize

    /// Generates layout attributes for the given items.
    ///
    /// - parameter size: The size that layout attributes should be generated
    ///   within.
    ///
    /// - parameter items: An array of 'items', pairs consisting of a traits
    ///   object and a `Measurable` value.
    ///
    /// - returns: Layout attributes for the given array of items.
    func layout(
        items: LayoutItems<Self.Traits>,
        in size : CGSize,
        with context : LayoutContext
    ) -> [LayoutAttributes]
    
    /// Returns a default traits object.
    static var defaultTraits: Self.Traits { get }
    
}


extension Layout where Traits == () {
    
    public static var defaultTraits: () {
        return ()
    }
}


/// Provides a list of items to measure or position during the element layout and measurement pass.
/// You can measure each item by calling `content.measure(in:with:)`, passing the
/// desired size and ``LayoutContent`` to propagate the ``Environment``, etc.
public final class LayoutItems<Traits> {
    
    /// The items to be measured or laid out.
    public let all : [Item]
    
    /// The count of the items to be measured or laid out.
    public let count : Int
    
    init(with all : [Item]) {
        self.all = all
        self.count = self.all.count
    }
    
    /// An individual item to layout or measure.
    public struct Item {
        
        /// The traits associated with the item, from its containing `Layout`. For most layouts, the `Traits`
        /// are `()`, or `Void`.
        public let traits : Traits
        
        /// The content of the layout item to be measured.
        public let content : Measurable
        
        init(traits: Traits, content: Measurable) {
            self.traits = traits
            self.content = content
        }
    }
}

