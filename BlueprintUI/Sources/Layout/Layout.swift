import CoreGraphics

/// A type that defines the geometry of a collection of elements.
///
/// You traditionally arrange views in your app's user interface using built-in layout containers
/// like ``Row`` and ``Column``. If you need more complex layout behavior, you can define a custom
/// layout container by creating a type that conforms to the ``Layout`` protocol and implementing
/// its required methods:
///
/// - ``CaffeinatedLayout/sizeThatFits(proposal:subelements:environment:cache:)`` reports the sizes
///   of the composite layout.
/// - ``CaffeinatedLayout/placeSubelements(in:subelements:environment:cache:)`` assigns positions to
///   the container's subelements.
///
/// You can define a basic layout type with only these two methods (see note below):
///
/// ```swift
/// struct BasicLayout: Layout {
///     func sizeThatFits(
///         proposal: SizeConstraint,
///         subelements: Subelements,
///         cache: inout ()
///     ) -> CGSize {
///         // Calculate and return the size of the layout container.
///     }
///
///     func placeSubelements(
///         in size: CGSize,
///         subelements: Subelements,
///         cache: inout ()
///     ) {
///         // Tell each subelement where to appear.
///     }
/// }
/// ```
///
/// Add your layout to an element by passing it to the `ElementContent` initializer
/// ``ElementContent/init(layout:configure:)``. If your layout has parameters that come from the
/// element, pass them at initialization time. Use the `configure` block to add your element's
/// children to the content.
///
/// ```swift
/// struct BasicContainer: Element {
///     var alignment: Alignment = .center
///     var children: [Element]
///
///     var content: ElementContent {
///         ElementContent(layout: BasicLayout(alignment: alignment)) { builder in
///             for child in children {
///                 builder.add(element: child)
///             }
///         }
///     }
///
///     func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
///         nil
///     }
/// }
/// ```
///
/// If your layout is specialized for laying out a single subelement, you can use the
/// ``SingleChildLayout`` protocol instead. It has similar methods, but is strongly typed for a
/// single subelement instead of a collection.
///
/// - Note: During the transition from Blueprint's legacy layout system to Caffeinated Layout, the
///   ``Layout`` protocol is composed of two sets of layout methods: ``LegacyLayout`` and
///   ``CaffeinatedLayout``. While this documentation focuses on the newer layout API, you must
///   currently implement both. Fortunately, the methods are similar, and you may be able to reuse
///   logic.
///
/// ## Interact with subelements through their proxies
///
/// To perform layout, you need information about all of your container's subelements, which are the
/// child elements that your container arranges. While your layout can’t interact directly with its
/// subelements, it can access a set of subelement proxies through the
/// ``CaffeinatedLayout/Subelements`` collection that each protocol method receives as an input
/// parameter. That type is an alias for the ``LayoutSubelements`` collection type, which in turn
/// contains ``LayoutSubelement`` instances that are the subelement proxies.
///
/// You can get information about each subelement from its proxy, like its dimensions and traits.
/// This enables you to measure subelements before you commit to placing them. You also assign a
/// position to each subelement by calling its proxy’s ``LayoutSubelement/place(at:anchor:size:)``
/// method. Call the method on each subelement from within your implementation of the layout’s
/// ``CaffeinatedLayout/placeSubelements(in:subelements:environment:cache:)`` method.
///
/// ## Access layout traits
///
/// Subelements may have _traits_ that are specific to their container's layout. The traits are of
/// the ``Layout`` protocol's associated type ``LegacyLayout/Traits``, and each subelement can have
/// a distinct `Traits` value assigned. You can set this in the `configure` block of
/// ``ElementContent/init(layout:configure:)``, when you call
/// ``ElementContent/Builder/add(traits:key:element:)``. If you do not specify a `Traits` type for
/// your layout, it defaults to the void type, `()`.
///
/// Containers can choose to condition their behavior according to the traits of their subelements.
/// For example, the ``Row`` and ``Column`` types allocate space for their subelements based in part
/// on the grow and shrink priorities that you set on each child. Your layout container accesses the
/// traits for a subelement by calling ``LayoutSubelement/traits(forLayoutType:)`` on the
/// ``LayoutSubelement`` proxy.
///
/// - Note: The ``Layout`` API, and its documentation, are modeled after SwiftUI's
///   [Layout](https://developer.apple.com/documentation/swiftui/layout), with major differences
///   noted.
///
public protocol Layout: LegacyLayout, CaffeinatedLayout {}

public protocol LegacyLayout {
    /// Per-item metadata that is used during the measuring and layout pass.
    associatedtype Traits = ()

    /// Computes the size that this layout requires in a layout, given an array of children and
    /// accompanying layout traits.
    ///
    /// - parameter constraint: The size constraint in which measuring should occur.
    /// - parameter items: An array of 'items', pairs consisting of a traits object and a
    ///   `Measurable` value.
    ///
    /// - returns: The measured size for the given array of items.
    func measure(in constraint: SizeConstraint, items: [(traits: Self.Traits, content: Measurable)]) -> CGSize

    /// Generates layout attributes for the given items.
    ///
    /// - parameter size: The size that layout attributes should be generated within.
    ///
    /// - parameter items: An array of 'items', pairs consisting of a traits object and a
    ///   `Measurable` value.
    ///
    /// - returns: Layout attributes for the given array of items.
    func layout(size: CGSize, items: [(traits: Self.Traits, content: Measurable)]) -> [LayoutAttributes]

    /// Returns a default traits object.
    static var defaultTraits: Self.Traits { get }

}

extension LegacyLayout where Traits == () {

    public static var defaultTraits: () {
        return ()
    }

}

public protocol CaffeinatedLayout {

    typealias Subelements = LayoutSubelements

    /// Cached values associated with the layout instance.
    ///
    /// If you create a cache for your custom layout, you can use a type alias to define this type
    /// as your data storage type. Alternatively, you can refer to the data storage type directly in
    /// all the places where you work with the cache.
    ///
    /// See ``makeCache(subelements:environment:)-8ciko`` for more information.
    associatedtype Cache = Void

    /// Returns the size of the composite element, given a proposed size constraint and the
    /// container's subelements.
    ///
    /// Implement this method to tell your custom layout container’s parent how much space the
    /// container needs for a set of subelements, given a size constraint. The parent might call
    /// this method more than once during a layout pass with different proposed sizes to test the
    /// flexibility of the container.
    ///
    /// In Blueprint, parents ultimately choose the size of their children, so the actual size that
    /// this container is laid out in may not be a size that was returned from this method.
    ///
    /// ## Sizing Rules
    ///
    /// For performance reasons, the layout engine may deduce the measurement of your container for
    /// some constraint values without explicitly calling
    /// ``sizeThatFits(proposal:subelements:environment:cache:)``. To ensure that the deduced value
    /// is correct, your layout must follow some ground rules:
    ///
    /// 1. **Given one fixed constraint axis, the element's growth along the other axis should be
    ///    _monotonic_.** That is, an element can grow when given a larger constraint, or shrink
    ///    when given a smaller constraint, but it should never shrink when given a larger
    ///    constraint. When growing on one axis, it is OK to shrink along the other axis, such as a
    ///    block of text that re-flows as the width changes.
    /// 2. For a constraint axis value _a_, if an element has a length _b_ that is less than _a_ on
    ///    that axis, then the element must return _b_ for **all constraint values between _a_ and
    ///    _b_**. In other words, growth must follow a stair-step pattern; elements that grow
    ///    continuously by calculating a fixed inset of the constraint or a percentage value of the
    ///    constraint are forbidden. For example, if an element returns `10` for a constraint of
    ///    `20`, then the element must return `10` for all values in the range `[10, 20]`.
    /// 3. If your element has no intrinsic size along an axis, you can represent that in a couple
    ///     ways:
    ///     - You can return a fixed value representing the minimum size for your element. In this
    ///       approach, a containing element is usually responsible for stretching your element to
    ///       fill desired space.
    ///     - You can return a size that entirely fills the constraint proposed. In this approach,
    ///       you **must** return `.infinity` when the constraint is
    ///       ``SizeConstraint/Axis/unconstrained``. Otherwise, your behavior would be in violation
    ///       of rule #1.
    ///
    /// If an element does not adhere to these rules, it may lay out in unexpected and unpredictable
    /// ways.
    ///
    /// - Parameters:
    ///   - proposal: A size constraint for the container. The container's parent element that calls
    ///     this method might call the method more than once with different constraints to learn
    ///     more about the container’s flexibility before choosing a size for placement.
    ///   - subelements: A collection of proxies that represent the elements that the container
    ///     arranges. You can use the proxies in the collection to get information about the
    ///     subelements as you determine how much space the container needs to display them.
    ///   - environment: The environment of the container. You can use properties from the
    ///     environment when calculating the size of this container, as long as you adhere to the
    ///     sizing rules.
    ///   - cache: Optional storage for calculated data that you can share among the methods of your
    ///     custom layout container. See ``makeCache(subelements:environment:)-8ciko`` for details.
    /// - Returns: A size that indicates how much space the container needs to arrange its
    ///   subelements.
    func sizeThatFits(
        proposal: SizeConstraint,
        subelements: Subelements,
        environment: Environment,
        cache: inout Cache
    ) -> CGSize

    /// Assigns positions to each of the layout’s subelements.
    ///
    /// Blueprint calls your implementation of this method to tell your custom layout container to
    /// place its subelements. From this method, call the
    /// ``LayoutSubelement/place(at:anchor:size:)`` method on each item in `subelements` to tell the
    /// subelements where to appear in the user interface.
    ///
    /// You can also update the ``LayoutSubelement/attributes-swift.property`` property of each
    /// subelement to set properties like opacity and transforms on each subelement.
    ///
    /// Be sure that you use computations during placement that are consistent with those in your
    /// implementation of other protocol methods for a given set of inputs. For example, if you add
    /// spacing during placement, make sure your implementation of
    /// ``sizeThatFits(proposal:subelements:environment:cache:)`` accounts for the extra space.
    ///
    /// - Parameters:
    ///   - size: The region that the container's parent allocates to the container. Place all the
    ///     container's subelements within the region. The size of this region may not match any
    ///     size that was returned from a call to
    ///     ``sizeThatFits(proposal:subelements:environment:cache:)``.
    ///   - subelements: A collection of proxies that represent the elements that the container
    ///     arranges. Use the proxies in the collection to get information about the subelements and
    ///     to tell the subelements where to appear.
    ///   - environment: The environment of this container. You can use properties from the
    ///     environment to vary the placement of subelements.
    ///   - cache: Optional storage for calculated data that you can share among the methods of your
    ///     custom layout container. See ``makeCache(subelements:environment:)-8ciko`` for details.
    func placeSubelements(
        in size: CGSize,
        subelements: Subelements,
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
    /// calculations across calls to ``sizeThatFits(proposal:subelements:environment:cache:)`` and
    /// ``placeSubelements(in:subelements:environment:cache:)``. You might be able to improve
    /// performance by calculating values once and storing them in a cache.
    ///
    /// - Note: A cache's lifetime is limited to a single render pass, so you cannot use it to store
    ///   values across multiple calls to ``placeSubelements(in:subelements:environment:cache:)``. A
    ///   render pass includes zero, one, or many calls to
    ///   ``sizeThatFits(proposal:subelements:environment:cache:)``, followed by a single call to
    ///   ``placeSubelements(in:subelements:environment:cache:)``.
    ///
    /// Only implement a cache if profiling shows that it improves performance.
    ///
    /// ## Initializing a cache
    ///
    /// Implement the `makeCache(subelements:)` method to create a cache. You can add computed
    /// values to the cache right away, using information from the subelements input parameter, or
    /// you can do that later. The methods of the ``Layout`` protocol that can access the cache take
    /// the cache as an in-out parameter, which enables you to modify the cache anywhere that you
    /// can read it.
    ///
    /// You can use any storage type that makes sense for your layout algorithm, but be sure that
    /// you only store data that you derive from the layout and its subelements (lazily, if
    /// possible). For this to work correctly, Blueprint needs to be able to call this method to
    /// recreate the cache without changing the layout result.
    ///
    /// When you return a cache from this method, you implicitly define a type for your cache. Be
    /// sure to either make the type of the cache parameters on your other ``Layout`` protocol
    /// methods match, or use a type alias to define the ``Cache`` associated type.
    ///
    /// - Parameter subelements: A collection of proxy instances that represent the subelements that
    ///   the container arranges. You can use the proxies in the collection to get information about
    ///   the subelements as you calculate values to store in the cache.
    /// - Parameter environment: The environment of this container.
    /// - Returns: Storage for calculated data that you share among the methods of your custom
    ///   layout container.
    func makeCache(subelements: Subelements, environment: Environment) -> Cache
}

extension CaffeinatedLayout where Cache == () {
    public func makeCache(subelements: Subelements, environment: Environment) { () }
}
