import UIKit

/// Represents the content of an element.
public struct ElementContent {

    private let storage: ContentStorage
    
    /// The key to use to cache measurement values.
    private let measurementCachingKey : MeasurementCachingKey?
    
    //
    // MARK: Initialization
    //

    /// Initializes a new `ElementContent` with the given layout and children.
    ///
    /// - parameter layout: The layout to use.
    /// - parameter measurementCachingKey: An optional key to use to cache measurement. See the `MeasurementCachingKey` documentation for more.
    /// - parameter configure: A closure that configures the layout and adds children to the container.
    public init<LayoutType: Layout>(
        layout: LayoutType,
        measurementCachingKey : MeasurementCachingKey? = nil,
        configure: (inout Builder<LayoutType>) -> Void = { _ in }
    ) {
        var builder = Builder(layout: layout)
        configure(&builder)
        
        self.storage = builder
        self.measurementCachingKey = measurementCachingKey
    }

    func measure(
        in constraint : SizeConstraint,
        with context: LayoutContext,
        states: ElementState
    ) -> CGSize
    {
        context.measurementCache.measurement(with: self.measurementCachingKey, in: constraint) {
            self.storage.measure(in: constraint, with: context, states: states)
        }
    }

    public var childCount: Int {
        storage.childCount
    }

    func performLayout(
        in size: CGSize,
        with context : LayoutContext,
        states : ElementState
    ) -> [(identifier: ElementIdentifier, node: LayoutResultNode)] // TODO: Turn this into a reference type too
    {
        storage.performLayout(
            in: size,
            with: context,
            states: states
        )
    }
}


 extension Element {
    
    // MARK: Measurement & Children
    
    /// Measures the size needed to display the element within the provided size constraint.
    ///
    /// ### Usage
    /// You usually call this method from within the `measure` method of a `Layout`, or within the
    /// measurement function you provide to an `ElementContent` instance. In either of these cases,
    /// you should pass through the `LayoutContext` provided to you to ensure the measured elements
    /// downstream have full access to their measurement caches, environment, etc.
    /// ```
    /// public var content: ElementContent {
    ///     ElementContent { constraint, context -> CGSize in
    ///         self.wrapped.measure(in: constraint, with: context)
    ///     }
    /// }
    /// ```
    public func measure(in constraint : SizeConstraint, with context: LayoutContext) -> CGSize {
        
        let root = RootElementState(name: "\(type(of:self)).measure")
        root.update(with: self)
        
        return self.content.measure(
            in: constraint,
            with: context,
            states: root.root!
        )
    }
}


extension ElementContent {
    
    /// Initializes a new `ElementContent` that will lazily create its storage during a layout and measurement pass,
    /// based on the `Environment` passed to the `builder` closure.
    ///
    /// - parameter measurementCachingKey: An optional key to use to cache measurement. See the `MeasurementCachingKey`
    ///     documentation for more.
    /// - parameter builder: A closure that provides the content `Element` based on the provided `SizeConstraint`
    ///     and `LayoutContext`.
    public init(
        measurementCachingKey : MeasurementCachingKey? = nil,
        build builder: @escaping (SizeConstraint, LayoutContext) -> Element
    ) {
        self.measurementCachingKey = measurementCachingKey
        self.storage = LazyStorage(builder: builder)
    }
}

extension ElementContent {

    /// Initializes a new `ElementContent` with the given element and layout.
    ///
    /// - parameter element: The single child element.
    /// - parameter key: The key to use to unique the element during updates.
    /// - parameter layout: The layout that will be used.
    /// - parameter measurementCachingKey: An optional key to use to cache measurement. See the `MeasurementCachingKey` documentation for more.
    public init(
        child: Element,
        key : AnyHashable? = nil,
        layout: SingleChildLayout,
        measurementCachingKey : MeasurementCachingKey? = nil
    ) {
        self = ElementContent(
            layout: SingleChildLayoutHost(wrapping: layout),
            measurementCachingKey: measurementCachingKey
        ) {
            $0.add(key: key, element: child)
        }
    }

    /// Initializes a new `ElementContent` with the given element.
    ///
    /// The given element will be used for measuring, and it will always fill the extent of the parent element.
    ///
    /// - parameter element: The single child element.
    /// - parameter measurementCachingKey: An optional key to use to cache measurement. See the `MeasurementCachingKey` documentation for more.
    public init(
        child: Element,
        measurementCachingKey : MeasurementCachingKey? = nil
    ) {
        self = ElementContent(
            child: child,
            layout: PassthroughLayout(),
            measurementCachingKey: measurementCachingKey
        )
    }

    /// Initializes a new `ElementContent` with no children that delegates to the provided `Measurable`.
    ///
    /// - parameter measurable: How to measure the `ElementContent`.
    /// - parameter measurementCachingKey: An optional key to use to cache measurement. See the `MeasurementCachingKey` documentation for more.
    public init(
        measurable: Measurable,
        measurementCachingKey : MeasurementCachingKey? = nil
    ) {
        self = ElementContent(
            layout: MeasurableLayout(measurable: measurable),
            measurementCachingKey: measurementCachingKey,
            configure: { _ in }
        )
    }

    /// Initializes a new `ElementContent` with no children that delegates to the provided measure function.
    ///
    /// - parameter measurementCachingKey: An optional key to use to cache measurement. See the `MeasurementCachingKey` documentation for more.
    /// - parameter measureFunction: How to measure the `ElementContent` in the given `SizeConstraint` and `LayoutContext`.
    public init(
        measurementCachingKey : MeasurementCachingKey? = nil,
        measureFunction: @escaping (SizeConstraint, LayoutContext) -> CGSize
    ) {
        self = ElementContent(
            measurable: Measurer(provider: measureFunction),
            measurementCachingKey: measurementCachingKey
        )
    }

    /// Initializes a new `ElementContent` with no children that uses the provided intrinsic size for measuring.
    public init(intrinsicSize: CGSize) {
        self = ElementContent { _, _ in intrinsicSize }
    }
}

extension ElementContent {
    
    /// Initializes a new `ElementContent` with the given child element, measurement caching key, and environment adapter,
    /// which allows adapting the environment to affect the element, plus elements further down the tree.
    ///
    /// - parameter child: The child element to display.
    /// - parameter measurementCachingKey: An optional key to use to cache measurement. See the `MeasurementCachingKey` documentation for more.
    /// - parameter environmentAdapter: How to adapt the `Environment` for the child and elements further down the tree.
    public init(
        child: Element,
        measurementCachingKey : MeasurementCachingKey? = nil,
        environment adapter: @escaping (inout Environment) -> Void
    ) {
        self.measurementCachingKey = measurementCachingKey
        
        self.storage = EnvironmentAdaptingStorage(
            adapter: adapter,
            child: child
        )
    }

    /// Initializes a new `ElementContent` with the given child element, measurement caching key, and environment key + value.
    /// which adapts the environment to affect the element, plus elements further down the tree.
    ///
    /// - parameter child: The child element to display.
    /// - parameter key: The key to set in the `Environment`.
    /// - parameter value: The value to set in the `Environment` for the given key.
    /// - parameter measurementCachingKey: An optional key to use to cache measurement. See the `MeasurementCachingKey` documentation for more.
    public init<Key>(
        child: Element,
        key: Key.Type,
        value: Key.Value,
        measurementCachingKey : MeasurementCachingKey? = nil
    ) where Key: EnvironmentKey {
        
        self.init(child: child, measurementCachingKey: measurementCachingKey) { environment in
            environment[key] = value
        }
    }
}


fileprivate protocol ContentStorage {
    
    var childCount: Int { get }
    
    func measure(
        in constraint : SizeConstraint,
        with context : LayoutContext,
        states: ElementState
    ) -> CGSize

    func performLayout(
        in size: CGSize,
        with context : LayoutContext,
        states: ElementState
    ) -> [(identifier: ElementIdentifier, node: LayoutResultNode)]
}


extension ElementContent {

    public struct Builder<LayoutType: Layout> : ContentStorage {

        /// The layout object that is ultimately responsible for measuring
        /// and layout tasks.
        public var layout: LayoutType

        /// Child elements.
        fileprivate var children: [Child] = []

        init(layout: LayoutType) {
            self.layout = layout
        }

        /// Adds the given child element.
        public mutating func add(traits: LayoutType.Traits = LayoutType.defaultTraits, key: AnyHashable? = nil, element: Element) {
            let child = Child(
                traits: traits,
                key: key,
                content: element.content,
                element: element
            )
            
            children.append(child)
        }
        
        // MARK: ContentStorage
        
        var childCount: Int {
            return children.count
        }

        func measure(
            in constraint : SizeConstraint,
            with context : LayoutContext,
            states: ElementState
        ) -> CGSize
        {
            states.measure(in: constraint) {
                
                Logger.logMeasureStart(
                    object: states.signpostRef,
                    description: states.name,
                    constraint: constraint
                )
                
                defer { Logger.logMeasureEnd(object: states.signpostRef) }

                let layoutItems = self.layoutItems(states: states)
                
                return layout.measure(
                    items: layoutItems,
                    in: constraint,
                    with: context
                )
            }
        }

        func performLayout(
            in size : CGSize,
            with context : LayoutContext,
            states: ElementState
        ) -> [(identifier: ElementIdentifier, node: LayoutResultNode)]
        {
            guard self.children.isEmpty == false else {
                return []
            }
            
            let layoutItems = self.layoutItems(states: states)
            
            let childAttributes = layout.layout(
                items: layoutItems,
                in: size,
                with: context
            )

            var result: [(identifier: ElementIdentifier, node: LayoutResultNode)] = []
            result.reserveCapacity(children.count)
            
            for index in 0..<children.count {
                let currentChildLayoutAttributes = childAttributes[index]
                let currentChild = children[index]

                let identifier = layoutItems.all[index].identifier

                let resultNode = LayoutResultNode(
                    element: currentChild.element,
                    layoutAttributes: currentChildLayoutAttributes,
                    environment: context.environment,
                    children: currentChild.content.performLayout(
                        in: currentChildLayoutAttributes.frame.size,
                        with: context,
                        states: states.subState(for: currentChild.element, with: identifier)
                    )
                )

                result.append((identifier: identifier, node: resultNode))
            }

            return result
        }

        private func layoutItems(
            states : ElementState
        ) -> LayoutItems<LayoutType.Traits>
        {
            /// **Note**: We are intentionally using our `indexedMap(...)` and not `enumerated().map(...)`
            /// here; because the enumerated version is about 25% slower. Because this
            /// is an extremely hot codepath; this additional performance matters, so we will
            /// keep track of the index ourselves.
            
            var identifierFactory = ElementIdentifier.Factory(elementCount: children.count)
            
            return LayoutItems(with: children.indexedMap { index, child in
                let childContent = child.content
                
                let identifier = identifierFactory.nextIdentifier(for: type(of: child.element), key: child.key)
                
                let measurable = Measurer { constraint, context in
                    childContent.measure(
                        in: constraint,
                        with: context,
                        states: states.subState(for: child.element, with: identifier)
                    )
                }
                
                return LayoutItems.Item(
                    traits: child.traits,
                    content: measurable,
                    identifier: identifier
                )
            })
        }
        
        fileprivate struct Child {

            var traits: LayoutType.Traits
            var key: AnyHashable?
            var content: ElementContent
            var element: Element

        }
    }
}


private struct EnvironmentAdaptingStorage: ContentStorage {
    
    let childCount = 1
    
    /// During measurement or layout, the environment adapter will be applied
    /// to the environment before passing it
    ///
    var adapter: (inout Environment) -> Void

    var child: Element

    func performLayout(
        in size : CGSize,
        with context : LayoutContext,
        states: ElementState
    ) -> [(identifier: ElementIdentifier, node: LayoutResultNode)]
    {
        let environment = adapted(environment: context.environment)

        let childAttributes = LayoutAttributes(size: size)

        let identifier = ElementIdentifier(elementType: type(of: child), key: nil, count: 1)

        let node = LayoutResultNode(
            element: child,
            layoutAttributes: childAttributes,
            environment: environment,
            children: child.content.performLayout(
                in: size,
                with: context.setting(\.environment, to: environment),
                states: states.subState(for: child, with: identifier)
            )
        )

        return [(identifier, node)]
    }

    func measure(
        in constraint : SizeConstraint,
        with context : LayoutContext,
        states: ElementState
    ) -> CGSize
    {
        states.measure(in: constraint) {
            let environment = adapted(environment: context.environment)
            
            let identifier = ElementIdentifier(elementType: type(of: child), key: nil, count: 1)
            
            return child.content.measure(
                in: constraint,
                with: context.setting(\.environment, to: environment),
                states: states.subState(for: child, with: identifier)
            )
        }
    }

    private func adapted(environment: Environment) -> Environment {
        var environment = environment
        adapter(&environment)
        return environment
    }
}

/// Content storage that defers creation of its child until measurement or layout time.
private struct LazyStorage: ContentStorage {
    
    let childCount = 1

    var builder: (SizeConstraint, LayoutContext) -> Element
    
    func measure(
        in constraint : SizeConstraint,
        with context : LayoutContext,
        states: ElementState
    ) -> CGSize
    {
        states.measure(in: constraint) {
            let child = builder(constraint, context)
            
            let identifier = ElementIdentifier(elementType: type(of: child), key: nil, count: 1)
            
            return child.content.measure(
                in: constraint,
                with: context,
                states: states.subState(for: child, with: identifier)
            )
        }
    }

    func performLayout(
        in size: CGSize,
        with context : LayoutContext,
        states: ElementState
    ) -> [(identifier: ElementIdentifier, node: LayoutResultNode)]
    {
        let child = builder(SizeConstraint(size), context)
        
        let childAttributes = LayoutAttributes(size: size)

        let identifier = ElementIdentifier(elementType: type(of: child), key: nil, count: 1)

        let node = LayoutResultNode(
            element: child,
            layoutAttributes: childAttributes,
            environment: context.environment,
            children: child.content.performLayout(
                in: size,
                with: context,
                states: states.subState(for: child, with: identifier)
            )
        )

        return [(identifier, node)]
    }
}


// All layout is ultimately performed by the `Layout` protocol – this implementations delegates to a wrapped
// `SingleChildLayout` implementation for use in elements with a single child.
fileprivate struct SingleChildLayoutHost: Layout {

    private var wrapped: SingleChildLayout

    init(wrapping layout: SingleChildLayout) {
        self.wrapped = layout
    }
    
    // MARK: Layout
    
    func measure(
        items: LayoutItems<Void>,
        in constraint : SizeConstraint,
        with context: LayoutContext
    ) -> CGSize
    {
        precondition(items.count == 1)
        return wrapped.measure(
            child: items.all[0].content,
            in: constraint,
            with: context
        )
    }

    func layout(
        items: LayoutItems<Void>,
        in size : CGSize,
        with context : LayoutContext
    ) -> [LayoutAttributes]
    {
        precondition(items.count == 1)
        return [
            wrapped.layout(child: items.all[0].content, in: size, with: context)
        ]
    }
}


// Used for elements with a single child that requires no custom layout
fileprivate struct PassthroughLayout: SingleChildLayout {
        
    func measure(
        child: Measurable,
        in constraint : SizeConstraint,
        with context: LayoutContext
    ) -> CGSize
    {
        child.measure(in: constraint, with: context)
    }

    func layout(
        child: Measurable,
        in size : CGSize,
        with context : LayoutContext
    ) -> LayoutAttributes
    {
        LayoutAttributes(size: size)
    }
}


// Used for empty elements with an intrinsic size
fileprivate struct MeasurableLayout: Layout {

    let measurable: Measurable

    func measure(
        items: LayoutItems<Void>,
        in constraint : SizeConstraint,
        with context: LayoutContext
    ) -> CGSize
    {
        precondition(items.all.isEmpty)
        return measurable.measure(in: constraint, with: context)
    }

    func layout(
        items: LayoutItems<Void>,
        in size : CGSize,
        with context : LayoutContext
    ) -> [LayoutAttributes]
    {
        precondition(items.all.isEmpty)
        return []
    }

}

struct Measurer: Measurable {
    
    let provider: (SizeConstraint, LayoutContext) -> CGSize
    
    func measure(
        in constraint : SizeConstraint,
        with context : LayoutContext
    ) -> CGSize
    {
        self.provider(constraint, context)
    }
}
