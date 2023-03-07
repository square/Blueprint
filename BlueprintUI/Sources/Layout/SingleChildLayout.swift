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
    /// See ``makeCache(subelement:)-33y4l`` for more information.
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
    /// ## Sizing Rules
    ///
    /// For performance reasons, the layout engine may deduce the measurement of your container for
    /// some constraint values without explicitly calling
    /// ``sizeThatFits(proposal:subelement:cache:)``. To ensure that the deduced value is correct,
    /// your layout must follow some ground rules:
    ///
    /// 1. **Given one fixed constraint axis, the element's growth along the other axis should be
    ///    _monotonic_.** That is, an element can grow when given a larger constraint, or shrink
    ///    when given a smaller constraint, but it should never shrink when given a larger
    ///    constraint. When growing on one axis, it is OK to shrink along the other axis, such as a
    ///    block of text that re-flows as the width changes.
    /// 2. If your element has no intrinsic size along an axis, you can represent that in a couple
    ///     ways:
    ///     - You can return a fixed value representing the minimum size for your element. In this
    ///       approach, a containing element is usually responsible for stretching your element to
    ///       fill desired space.
    ///     - You can return a size that entirely fills the constraint proposed. In this approach,
    ///       you **must** return `.infinity` when the constraint is
    ///       ``SizeConstraint/Axis/unconstrained``. Otherwise, your behavior would be in violation
    ///       of rule #1.
    ///
    /// - Parameters:
    ///   - proposal: A size constraint for the container. The container's parent element that calls
    ///     this method might call the method more than once with different constraints to learn
    ///     more about the container’s flexibility before choosing a size for placement.
    ///   - subelement: A proxy that represents the element that the container arranges. You can use
    ///     the proxy to get information about the subelement as you determine how much space the
    ///     container needs to display it.
    ///   - cache: Optional storage for calculated data that you can share among the methods of your
    ///     custom layout container. See ``makeCache(subelement:)-33y4l`` for details.
    /// - Returns: A size that indicates how much space the container needs to arrange its
    ///   subelement.
    func sizeThatFits(
        proposal: SizeConstraint,
        subelement: Subelement,
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
    /// ``sizeThatFits(proposal:subelement:cache:)`` accounts for the extra space.
    ///
    /// - Parameters:
    ///   - size: The region that the container's parent allocates to the container. Place the
    ///     container's subelement within the region. The size of this region may not match any size
    ///     that was returned from a call to ``sizeThatFits(proposal:subelement:cache:)``.
    ///   - subelement: A proxy that represents the element that the container arranges. Use the
    ///     proxy to get information about the subelement and to tell the subelement where to
    ///     appear.
    ///   - cache: Optional storage for calculated data that you can share among the methods of your
    ///     custom layout container. See ``makeCache(subelement:)-33y4l`` for details.
    func placeSubelement(
        in size: CGSize,
        subelement: Subelement,
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
    /// calculations across calls to ``sizeThatFits(proposal:subelement:cache:)`` and
    /// ``placeSubelement(in:subelement:cache:)``. You might be able to improve performance by
    /// calculating values once and storing them in a cache.
    ///
    /// - Note: A cache's lifetime is limited to a single render pass, so you cannot use it to store
    ///   values across multiple calls to ``placeSubelement(in:subelement:cache:)``. A render pass
    ///   includes zero, one, or many calls to ``sizeThatFits(proposal:subelement:cache:)``,
    ///   followed by a single call to ``placeSubelement(in:subelement:cache:)``.
    ///
    /// Only implement a cache if profiling shows that it improves performance.
    ///
    /// ## Initializing a cache
    ///
    /// Implement the `makeCache(subelement:)` method to create a cache. You can add computed values
    /// to the cache right away, using information from the subelement input parameter, or you can
    /// do that later. The methods of the ``SingleChildLayout`` protocol that can access the cache
    /// take the cache as an in-out parameter, which enables you to modify the cache anywhere that
    /// you can read it.
    ///
    /// You can use any storage type that makes sense for your layout algorithm, but be sure that
    /// you only store data that you derive from the layout and its subelement (lazily, if
    /// possible). For this to work correctly, Blueprint needs to be able to call this method to
    /// recreate the cache without changing the layout result.
    ///
    /// When you return a cache from this method, you implicitly define a type for your cache. Be
    /// sure to either make the type of the cache parameters on your other ``SingleChildLayout``
    /// protocol methods match, or use a type alias to define the ``Cache`` associated type.
    ///
    /// - Parameter subelement: A proxy that represent the subelement that the container arranges.
    ///   You can use the proxy to get information about the subelement as you calculate values to
    ///   store in the cache.
    /// - Returns: Storage for calculated data that you share among the methods of your custom
    ///   layout container.
    func makeCache(subelement: Subelement) -> Cache
}

extension CaffeinatedSingleChildLayout where Cache == () {
    public func makeCache(subelement: Subelement) { () }
}
