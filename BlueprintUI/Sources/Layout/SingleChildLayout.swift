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

    /// Cached values associated with the layout instance.
    ///
    /// If you create a cache for your custom layout, you can use a type alias to define this type
    /// as your data storage type. Alternatively, you can refer to the data storage type directly in
    /// all the places where you work with the cache.
    ///
    /// See ``makeCache(subelement:environment:)-8vyl9`` for more information.
    associatedtype Cache = Void

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
    ///   - cache: Optional storage for calculated data that you can share among the methods of your
    ///     custom layout container. See ``makeCache(subelement:environment:)-8vyl9`` for details.
    /// - Returns: A size that indicates how much space the container needs to arrange its
    ///   subelement.
    func sizeThatFits(
        proposal: SizeConstraint,
        subelement: Subelement,
        environment: Environment,
        cache: inout Cache
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
    ///   - cache: Optional storage for calculated data that you can share among the methods of your
    ///     custom layout container. See ``makeCache(subelement:environment:)-8vyl9`` for details.
    func placeSubelement(
        in size: CGSize,
        subelement: Subelement,
        environment: Environment,
        cache: inout Cache
    )

    /// Creates and initializes a cache for a layout instance.
    ///
    /// You can optionally use a cache to preserve calculated values across calls to a layout
    /// container’s methods. Many layout types don’t need a cache, because Blueprint automatically
    /// caches the results of calls into layout methods, such as
    /// ``LayoutSubelement/sizeThatFits(_:)``. Rely on the protocol’s default implementation of this
    /// method if you don’t need a cache.
    ///
    /// However you might find a cache useful when the layout container repeats complex intermediate
    /// calculations across calls to ``sizeThatFits(proposal:subelement:environment:cache:)`` and
    /// ``placeSubelement(in:subelement:environment:cache:)``. You might be able to improve
    /// performance by calculating values once and storing them in a cache.
    ///
    /// - Note: A cache's lifetime is limited to a single render pass, so you cannot use it to store
    ///   values across multiple calls to ``placeSubelement(in:subelement:environment:cache:)``. A
    ///   render pass includes zero, one, or many calls to
    ///   ``sizeThatFits(proposal:subelement:environment:cache:)``, followed by a single call to
    ///   ``placeSubelement(in:subelement:environment:cache:)``.
    ///
    /// Only implement a cache if profiling shows that it improves performance.
    ///
    /// For more information, see ``CaffeinatedLayout/makeCache(subelements:environment:)-8ciko``.
    ///
    /// - Parameter subelement: A proxy that represent the subelement that the container arranges.
    ///   You can use the proxy to get information about the subelement as you calculate values to
    ///   store in the cache.
    /// - Parameter environment: The environment of this container.
    /// - Returns: Storage for calculated data that you share among the methods of your custom
    ///   layout container.
    func makeCache(subelement: Subelement, environment: Environment) -> Cache
}

extension CaffeinatedSingleChildLayout where Cache == () {
    public func makeCache(subelement: Subelement, environment: Environment) { () }
}
