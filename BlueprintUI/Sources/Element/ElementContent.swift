import UIKit

/// Represents the content of an element.
public struct ElementContent {

    fileprivate let storage: ContentStorage
    
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
    
    // MARK: Measurement & Children

    /// Measures the required size of this element's content.
    /// - Parameters:
    ///   - constraint: The size constraint.
    ///   - environment: The environment to measure in.
    /// - returns: The layout size needed by this content.
    public func measure(in constraint: SizeConstraint, environment: Environment) -> CGSize {
        environment.measurementCache.measurement(with: self.measurementCachingKey, in: constraint) {
            self.storage.measure(in: constraint, environment: environment)
        }
    }

    public var childCount: Int {
        return storage.childCount
    }

    func performLayout(attributes: LayoutAttributes, environment: Environment) -> [(identifier: ElementIdentifier, node: LayoutResultNode)] {
        storage.performLayout(attributes: attributes, environment: environment)
    }
}


extension ElementContent {
    
    /// Initializes a new `ElementContent` that will lazily create its storage during a layout and measurement pass,
    /// based on the `Environment` passed to the `builder` closure.
    ///
    /// - parameter measurementCachingKey: An optional key to use to cache measurement. See the `MeasurementCachingKey`
    ///     documentation for more.
    /// - parameter builder: A closure that provides the content `Element` based on the provided `SizeConstraint`
    ///     and `Environment`.
    public init(
        measurementCachingKey : MeasurementCachingKey? = nil,
        build builder: @escaping (SizeConstraint, Environment) -> Element
    ) {
        self.measurementCachingKey = measurementCachingKey
        self.storage = LazyStorage(builder: builder)
    }
}

extension ElementContent {

    /// Initializes a new `ElementContent` with the given element and layout.
    ///
    /// - parameter element: The single child element.
    /// - parameter layout: The layout that will be used.
    /// - parameter measurementCachingKey: An optional key to use to cache measurement. See the `MeasurementCachingKey` documentation for more.
    public init(
        child: Element,
        layout: SingleChildLayout,
        measurementCachingKey : MeasurementCachingKey? = nil
    ) {
        self = ElementContent(layout: SingleChildLayoutHost(wrapping: layout), measurementCachingKey: measurementCachingKey) {
            $0.add(element: child)
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
        self = ElementContent(child: child, layout: PassthroughLayout(), measurementCachingKey: measurementCachingKey)
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
    /// - parameter measureFunction: How to measure the `ElementContent` in the given `SizeConstraint`.
    public init(
        measurementCachingKey : MeasurementCachingKey? = nil,
        measureFunction: @escaping (SizeConstraint) -> CGSize
    ) {
        struct Measurer: Measurable {
            var _measure: (SizeConstraint) -> CGSize
            func measure(in constraint: SizeConstraint) -> CGSize {
                return _measure(constraint)
            }
        }
        
        self = ElementContent(measurable: Measurer(_measure: measureFunction), measurementCachingKey: measurementCachingKey)
    }

    /// Initializes a new `ElementContent` with no children that uses the provided intrinsic size for measuring.
    public init(intrinsicSize: CGSize) {
        self = ElementContent(measureFunction: { _ in intrinsicSize })
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
        environment environmentAdapter: @escaping (inout Environment) -> Void
    ) {
        self.measurementCachingKey = measurementCachingKey
        
        self.storage = EnvironmentAdaptingStorage(
            adapter: environmentAdapter,
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


extension ElementContent {
    func measurable(in environment: Environment) -> Measurable {
        struct EnvironmentMeasurable: Measurable {
            var environment: Environment
            var content: ElementContent

            func measure(in constraint: SizeConstraint) -> CGSize {
                return content.measure(in: constraint, environment: environment)
            }
        }

        return EnvironmentMeasurable(environment: environment, content: self)
    }
}


fileprivate protocol ContentStorage {
    var childCount: Int { get }

    func measure(in constraint: SizeConstraint, environment: Environment) -> CGSize

    func performLayout(
        attributes: LayoutAttributes,
        environment: Environment
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

        func measure(in constraint: SizeConstraint, environment: Environment) -> CGSize {
            let items = self.layoutItems(in: environment)
            SignpostLogger.log(
                name: "Layout Element",
                info: layout.loggingInfo(with: <#T##Measurable#>)
            ) {
                layout.measure(in: constraint, items: items)
            }
        }

        func performLayout(
            attributes: LayoutAttributes,
            environment: Environment
        )
            -> [(identifier: ElementIdentifier, node: LayoutResultNode)]
        {
            guard self.children.isEmpty == false else {
                return []
            }
            
            return SignpostLogger.log(
                name: "Layout Element",
                info: .init(type: type(of: LayoutType.self))
            ) {
                let layoutItems = self.layoutItems(in: environment)
                let childAttributes = layout.layout(size: attributes.bounds.size, items: layoutItems)

                var result: [(identifier: ElementIdentifier, node: LayoutResultNode)] = []
                result.reserveCapacity(children.count)
                
                var identifierFactory = ElementIdentifier.Factory(elementCount: children.count)

                for index in 0..<children.count {
                    let currentChildLayoutAttributes = childAttributes[index]
                    let currentChild = children[index]

                    let resultNode = LayoutResultNode(
                        element: currentChild.element,
                        layoutAttributes: currentChildLayoutAttributes,
                        content: currentChild.content,
                        environment: environment
                    )

                    let identifier = identifierFactory.nextIdentifier(
                        for: type(of: currentChild.element),
                        key: currentChild.key
                    )

                    result.append((identifier: identifier, node: resultNode))
                }

                return result
            }
        }

        private func layoutItems(in environment: Environment) -> [(LayoutType.Traits, Measurable)] {
            children.map { ($0.traits, $0.content.measurable(in: environment)) }
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
        attributes: LayoutAttributes,
        environment: Environment)
        -> [(identifier: ElementIdentifier, node: LayoutResultNode)]
    {
        SignpostLogger.log(
            name: "Layout Element",
            info: .init(type: type(of: child))
        ) {
            let environment = adapted(environment: environment)

            let childAttributes = LayoutAttributes(size: attributes.bounds.size)

            let identifier = ElementIdentifier(elementType: type(of: child), key: nil, count: 1)

            let node = LayoutResultNode(
                element: child,
                layoutAttributes: childAttributes,
                content: child.content,
                environment: environment)

            return [(identifier, node)]
        }
    }

    func measure(in constraint: SizeConstraint, environment: Environment) -> CGSize {
        
        SignpostLogger.log(
            name: "Measure Element 2",
            info: .init(type: type(of: child))
        ) {
            let environment = adapted(environment: environment)

            return child.content.measure(in: constraint, environment: environment)
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

    var builder: (SizeConstraint, Environment) -> Element

    func performLayout(
        attributes: LayoutAttributes,
        environment: Environment)
        -> [(identifier: ElementIdentifier, node: LayoutResultNode)]
    {
        let constraint = SizeConstraint(attributes.bounds.size)
        let child = buildChild(in: constraint, environment: environment)
        
        return SignpostLogger.log(
            name: "Layout Element",
            info: .init(type: type(of: child))
        ) {

            let childAttributes = LayoutAttributes(size: attributes.bounds.size)

            let identifier = ElementIdentifier(elementType: type(of: child), key: nil, count: 1)

            let node = LayoutResultNode(
                element: child,
                layoutAttributes: childAttributes,
                content: child.content,
                environment: environment)

            return [(identifier, node)]
        }
    }

    func measure(in constraint: SizeConstraint, environment: Environment) -> CGSize {
        
        let child = buildChild(in: constraint, environment: environment)
        
        return SignpostLogger.log(
            name: "Measure Element 3",
            info: .init(type: type(of: child))
        ) {
            child.content.measure(in: constraint, environment: environment)
        }
    }

    private func buildChild(in constraint: SizeConstraint, environment: Environment) -> Element {
        return builder(constraint, environment)
    }
}


// All layout is ultimately performed by the `Layout` protocol – this implementations delegates to a wrapped
// `SingleChildLayout` implementation for use in elements with a single child.
fileprivate struct SingleChildLayoutHost: Layout {

    private var wrapped: SingleChildLayout

    init(wrapping layout: SingleChildLayout) {
        self.wrapped = layout
    }

    func measure(in constraint: SizeConstraint, items: [(traits: (), content: Measurable)]) -> CGSize {
        precondition(items.count == 1)
        return wrapped.measure(in: constraint, child: items.first!.content)
    }

    func layout(size: CGSize, items: [(traits: (), content: Measurable)]) -> [LayoutAttributes] {
        precondition(items.count == 1)
        return [
            wrapped.layout(size: size, child: items.first!.content)
        ]
    }
    
    func assString() -> SignpostLogger.Info {
         .init(type: wrapped.childElementType)
    }
}


// Used for elements with a single child that requires no custom layout
fileprivate struct PassthroughLayout: SingleChildLayout {

    func measure(in constraint: SizeConstraint, child: Measurable) -> CGSize {
        return child.measure(in: constraint)
    }

    func layout(size: CGSize, child: Measurable) -> LayoutAttributes {
        return LayoutAttributes(size: size)
    }

    func elementType(for child: Measurable) -> Any.Type {
        type(of: child)
    }
}


// Used for empty elements with an intrinsic size
fileprivate struct MeasurableLayout: Layout {

    var measurable: Measurable

    func measure(in constraint: SizeConstraint, items: [(traits: (), content: Measurable)]) -> CGSize {
        precondition(items.isEmpty)
        return measurable.measure(in: constraint)
    }

    func layout(size: CGSize, items: [(traits: (), content: Measurable)]) -> [LayoutAttributes] {
        precondition(items.isEmpty)
        return []
    }

}
