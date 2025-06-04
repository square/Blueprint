import UIKit

/// A type that defines the geometry of a single element.
///
/// For convenience, you can implement this protocol instead of ``Layout`` when building a container
/// that always has a single child element.
///
/// For more information about writing custom layouts, see ``Layout``.
///
public protocol SingleChildLayout: LegacySingleChildLayout, CaffeinatedSingleChildLayout {}

public protocol LegacySingleChildLayout {

    /// Computes the size that this layout requires
    ///
    /// - parameter constraint: The size constraint in which measuring should occur.
    /// - parameter child: A `Measurable` representing the single child of this layout.
    ///
    /// - returns: The measured size.
    func measure(in constraint: SizeConstraint, child: Measurable) -> CGSize

    /// Generates layout attributes for the child.
    ///
    /// - parameter size: The size that layout attributes should be generated within.
    ///
    /// - parameter child: A `Measurable` representing the single child of this layout.
    ///
    /// - returns: Layout attributes for the child of this layout.
    func layout(size: CGSize, child: Measurable) -> LayoutAttributes

}

public protocol CaffeinatedSingleChildLayout {

    typealias Subelement = LayoutSubelement

    /// Returns the size of the element, given a proposed size constraint and the container's
    /// subelement.
    ///
    /// Implement this method to tell your custom layout container’s parent how much space the
    /// container needs for a subelement, given a size constraint. The parent might call this method
    /// more than once during a layout pass with different proposed sizes to test the flexibility of
    /// the container.
    ///
    /// In Blueprint, parents ultimately choose the size of their children, so the actual size that
    /// this container is laid out in may not be a size that was returned from this method.
    ///
    /// For more information, see
    /// ``CaffeinatedLayout/sizeThatFits(proposal:subelements:environment:cache:)``.
    ///
    /// - Parameters:
    ///   - proposal: A size constraint for the container. The container's parent element that calls
    ///     this method might call the method more than once with different constraints to learn
    ///     more about the container’s flexibility before choosing a size for placement.
    ///   - subelement: A proxy that represents the element that the container arranges. You can use
    ///     the proxy to get information about the subelement as you determine how much space the
    ///     container needs to display it.
    ///   - environment: The environment of the container. You can use properties from the
    ///     environment when calculating the size of this container, as long as you adhere to the
    ///     sizing rules.
    /// - Returns: A size that indicates how much space the container needs to arrange its
    ///   subelement.
    func sizeThatFits(
        proposal: SizeConstraint,
        subelement: Subelement,
        environment: Environment
    ) -> CGSize

    /// Assigns a position to the layout’s subelement.
    ///
    /// Blueprint calls your implementation of this method to tell your custom layout container to
    /// place its subelement. From this method, call the ``LayoutSubelement/place(at:anchor:size:)``
    /// method on `subelement` to tell the subelement where to appear in the user interface.
    ///
    /// You can also update the ``LayoutSubelement/attributes-swift.property`` property to set
    /// properties like opacity and transforms on the subelement.
    ///
    /// Be sure that you use computations during placement that are consistent with those in your
    /// implementation of other protocol methods for a given set of inputs. For example, if you add
    /// spacing during placement, make sure your implementation of
    /// ``sizeThatFits(proposal:subelement:environment:cache:)`` accounts for the extra space.
    ///
    /// - Parameters:
    ///   - size: The region that the container's parent allocates to the container. Place the
    ///     container's subelement within the region. The size of this region may not match any size
    ///     that was returned from a call to
    ///     ``sizeThatFits(proposal:subelement:environment:cache:)``.
    ///   - subelement: A proxy that represents the element that the container arranges. Use the
    ///     proxy to get information about the subelement and to tell the subelement where to
    ///     appear.
    ///   - environment: The environment of this container. You can use properties from the
    ///     environment to vary the placement of the subelement.
    func placeSubelement(
        in size: CGSize,
        subelement: Subelement,
        environment: Environment
    )

}
