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


public final class LayoutItems<Traits> {
    
    public let all : [Item]
    
    public let count : Int
    
    init(with all : [Item]) {
        self.all = all
        self.count = self.all.count
    }
    
    public struct Item {
        
        public let traits : Traits
        public let content : Measurable
        
        let identifier : ElementIdentifier
        
        init(traits: Traits, content: Measurable, identifier : ElementIdentifier) {
            self.traits = traits
            self.content = content
        }
    }
}

