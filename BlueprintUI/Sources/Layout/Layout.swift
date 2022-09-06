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
    func measure(in constraint: SizeConstraint, items: LayoutItems<Self.Traits>) -> CGSize

    /// Generates layout attributes for the given items.
    ///
    /// - parameter size: The size that layout attributes should be generated
    ///   within.
    ///
    /// - parameter items: An array of 'items', pairs consisting of a traits
    ///   object and a `Measurable` value.
    ///
    /// - returns: Layout attributes for the given array of items.
    func layout(size: CGSize, items: LayoutItems<Self.Traits>) -> [LayoutAttributes]

    /// Returns a default traits object.
    static var defaultTraits: Self.Traits { get }
}

extension Layout where Traits == () {

    public static var defaultTraits: () {
        return ()
    }

}


public final class LayoutItems<Traits> {

    public let all: [Item]

    public let count: Int
    public let isEmpty: Bool

    init(with all: [Item]) {
        self.all = all
        count = all.count
        isEmpty = all.isEmpty
    }

    public struct Item {

        public let traits: Traits
        public let content: Measurable

        let identifier: ElementIdentifier

        init(traits: Traits, content: Measurable, identifier: ElementIdentifier) {
            self.traits = traits
            self.content = content
            self.identifier = identifier
        }
    }
}
