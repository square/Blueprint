import UIKit

/// An element that dynamically builds its content based on the available space.
///
/// Use this element to build elements whose contents may change responsively to
/// different layouts.
///
/// ## Example
///
/// ```swift
/// GeometryReader { (geometry) -> Element in
///     let image: UIImage
///     switch geometry.constraint.width.maximum {
///     case ..<100:
///         image = UIImage(named: "small")!
///     case 100..<500:
///         image = UIImage(named: "medium")!
///     default:
///         image = UIImage(named: "large")!
///     }
///     return Image(image: image)
/// }
/// ```
///
public struct GeometryReader: Element {
    /// Return the contents of this element based on the current layout.
    var elementRepresentation: (GeometryProxy) -> Element

    public init(elementRepresentation: @escaping (GeometryProxy) -> Element) {
        self.elementRepresentation = elementRepresentation
    }

    public var content: ElementContent {
        ElementContent { _, constraint, environment, cache, spCache -> Element in
            self.elementRepresentation(
                GeometryProxy(
                    environment: environment,
                    constraint: constraint,
                    cache: cache,
                    spCache: spCache
                )
            )
        }
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        nil
    }
}

/// Contains information about the current layout being measured by GeometryReader
public struct GeometryProxy {
    var environment: Environment

    /// The size constraint of the element being laid out.
    public var constraint: SizeConstraint

    var cache: CacheTree
    var spCache: SPCacheNode

    /// Measure the given element, constrained to the same size as the `GeometryProxy` itself (unless a constraint is explicitly provided).
    public func measure(element: Element, key: String, in explicit: SizeConstraint? = nil) -> CGSize {
        element.content.measure(
            in: explicit ?? constraint,
            environment: environment,
            cache: CacheFactory.makeCache(name: "FOO"), // cache.subcache(element: element, isOOB: true),
            spCache: spCache.oobSubcache(identifier: key),
            // TODO: ? Is this right?
            layoutMode: RenderContext.current?.layoutMode ?? .default
        )
    }
}


extension ElementContent {

    fileprivate init(builder: @escaping (ElementContent.LayoutPhase, SizeConstraint, Environment, CacheTree, SPCacheNode) -> Element) {
        storage = GeometryReaderStorage(builder: builder)
    }

    private struct GeometryReaderStorage: ContentStorage {
        let childCount = 1

        var builder: (ElementContent.LayoutPhase, SizeConstraint, Environment, CacheTree, SPCacheNode) -> Element

        func performLayout(
            attributes: LayoutAttributes,
            environment: Environment,
            cache: CacheTree
        ) -> [(identifier: ElementIdentifier, node: LayoutResultNode)] {
            let constraint = SizeConstraint(attributes.bounds.size)
            let child = buildChild(
                for: .layout,
                in: constraint,
                environment: environment,
                cache: cache,
                spCache: .init()
            )
            let childAttributes = LayoutAttributes(size: attributes.bounds.size)

            let identifier = ElementIdentifier(elementType: type(of: child), key: nil, count: 1)

            let node = LayoutResultNode(
                element: child,
                layoutAttributes: childAttributes,
                environment: environment,
                children: child.content.performLayout(
                    attributes: childAttributes,
                    environment: environment,
                    cache: cache.subcache(element: child)
                )
            )

            return [(identifier, node)]
        }

        func measure(in constraint: SizeConstraint, environment: Environment, cache: CacheTree) -> CGSize {
            cache.get(constraint) { constraint -> CGSize in
                let child = buildChild(
                    for: .measurement,
                    in: constraint,
                    environment: environment,
                    cache: cache,
                    spCache: .init()
                )
                return child.content.measure(
                    in: constraint,
                    environment: environment,
                    cache: cache.subcache(element: child)
                )
            }
        }

        func sizeThatFits(proposal: SizeConstraint, context: MeasureContext) -> CGSize {
            context.cache.get(key: proposal) { proposal in
                let child = buildChild(
                    for: .measurement,
                    in: proposal,
                    environment: context.environment,
                    cache: CacheFactory.makeCache(name: "GeometryReaderDummy"),
                    spCache: context.cache
                )
                let context = MeasureContext(
                    cache: context.cache.subcache(key: 0),
                    environment: context.environment
                )
                return child.content.sizeThatFits(proposal: proposal, context: context)
            }
        }

        func performSinglePassLayout(proposal: SizeConstraint, context: SPLayoutContext) -> [IdentifiedNode] {
            let child = buildChild(
                for: .layout,
                in: proposal,
                environment: context.environment,
                cache: CacheFactory.makeCache(name: "GeometryReaderDummy"),
                spCache: context.cache
            )

            let childAttributes = LayoutAttributes(size: context.attributes.bounds.size)

            let identifier = ElementIdentifier(elementType: type(of: child), key: nil, count: 1)

            let context = SPLayoutContext(
                attributes: context.attributes,
                environment: context.environment,
                cache: context.cache.subcache(key: 0)
            )

            let node = LayoutResultNode(
                element: child,
                layoutAttributes: childAttributes,
                environment: context.environment,
                children: child.content.performSinglePassLayout(
                    proposal: proposal,
                    context: context
                )
            )

            return [(identifier, node)]
        }

        private func buildChild(
            for phase: ElementContent.LayoutPhase,
            in constraint: SizeConstraint,
            environment: Environment,
            cache: CacheTree,
            spCache: SPCacheNode
        ) -> Element {
            builder(phase, constraint, environment, cache, spCache)
        }
    }
}
