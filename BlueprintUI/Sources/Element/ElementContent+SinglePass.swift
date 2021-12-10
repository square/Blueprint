import Foundation


typealias LayoutResultChildren = [(identifier: ElementIdentifier, node: LayoutResultNode)]


extension ElementContent.Builder {
    func children(in context: SPLayoutContext) -> [(id: ElementIdentifier, element: Element)] {

        var identifierFactory = ElementIdentifier.Factory(elementCount: childCount)

        return children.map { child in
            let childElement = child.element
            let id = identifierFactory.nextIdentifier(for: type(of: childElement), key: child.key)
            return (id: id, element: childElement)
        }
    }

    func singlePassLayout(
        in context: SPLayoutContext,
        environment: Environment,
        cache: CacheTree
    ) -> SPSubtreeResult {

        guard let spl = layout as? SPLayout else {
//            let old = performLayout(
//                attributes: LayoutAttributes(size: context.proposedSize),
//                environment: environment,
//                cache: cache
//            )

            fatalError()
        }

        let children = self.children(in: context)
        let layoutChildren = children.indices.map { (index: Int) -> SPLayoutNode in
            let (id, child) = children[index]
            
            return SPLayoutNode(
                id: id,
                element: child,
                environment: environment,
                cache: cache.subcache(index: index, of: childCount, element: child)
            )
        }

        let intermediateResult = spl.layout(in: context, children: layoutChildren)

        return SPSubtreeResult(
            intermediate: intermediateResult,
            children: layoutChildren
        )
    }
}

extension EnvironmentAdaptingStorage {
    func singlePassLayout(
        in context: SPLayoutContext,
        environment: Environment,
        cache: CacheTree
    ) -> SPSubtreeResult {
        let environment = adapted(environment: environment)
        let identifier = ElementIdentifier(elementType: type(of: child), key: nil, count: 1)
        let cache = cache.subcache(element: child)

        // or, a NeutralLayout, and hoist the behavior to ElementContent

        let r = child.content.singlePassLayout(
            in: context,
            environment: environment,
            cache: cache
        )

        return SPSubtreeResult(
            intermediate: SPLayoutAttributes(
                size: r.intermediate.size,
                childPositions: [.zero]
            ),
            children: [
                SPLayoutNode(
                    id: identifier,
                    element: child,
                    environment: environment,
                    cache: cache
                )
            ]
        )
    }
}

extension LazyStorage {
    func singlePassLayout(
        in context: SPLayoutContext,
        environment: Environment,
        cache: CacheTree
    ) -> SPSubtreeResult {
        let child = buildChild(in: .init(context.proposedSize), environment: environment)
        let identifier = ElementIdentifier(elementType: type(of: child), key: nil, count: 1)
        let cache = cache.subcache(element: child)

        let r = child.content.singlePassLayout(
            in: context,
            environment: environment,
            cache: cache
        )

        return SPSubtreeResult(
            intermediate: SPLayoutAttributes(
                size: r.intermediate.size,
                childPositions: [.zero]
            ),
            children: [
                SPLayoutNode(
                    id: identifier,
                    element: child,
                    environment: environment,
                    cache: cache
                )
            ]
        )
    }
}


extension MeasurableStorage {
    func singlePassLayout(
        in context: SPLayoutContext,
        environment: Environment,
        cache: CacheTree
    ) -> SPSubtreeResult {
        let size = measure(
            in: .init(context.proposedSize),
            environment: environment,
            cache: cache
        )
        return SPSubtreeResult(
            intermediate: SPLayoutAttributes(
                size: size,
                childPositions: []),
            children: []
        )
    }
}


struct SPSubtreeResult {
    var intermediate: SPLayoutAttributes
    var children: [SPLayoutNode]

    func resolve() -> LayoutResultChildren {
        zip(intermediate.childPositions, children).map { position, node in
            let subtreeResult = node.ensuredResult
            let childSize = subtreeResult.intermediate.size
            let childFrame = CGRect(
                origin: position,
                size: childSize
            )
            let nodeAttributes = LayoutAttributes(frame: childFrame)

            let result = LayoutResultNode(
                element: node.element,
                layoutAttributes: nodeAttributes,
                environment: node.environment,
                children: subtreeResult.resolve()
            )

            return (node.id, result)
        }
    }
}

public struct SPLayoutContext {
//    var environment: Environment
//    var cache: CacheTree

    var proposedSize: CGSize
}

public struct SPLayoutAttributes {
    public var size: CGSize
    public var childPositions: [CGPoint]

    /// Corresponds to `UIView.isUserInteractionEnabled`.
    public var isUserInteractionEnabled: Bool = true

    /// Corresponds to `UIView.isHidden`.
    public var isHidden: Bool = false

    public var transform: CATransform3D = CATransform3DIdentity

    public var alpha: CGFloat = 1.0

    public init(size: CGSize, childPositions: [CGPoint] = []) {
        self.size = size
        self.childPositions = childPositions
    }
}

public protocol SPLayout {
    func layout(in context: SPLayoutContext, children: [SPLayoutable]) -> SPLayoutAttributes
}

public protocol SPLayoutable {
    func layout(in proposedSize: CGSize) -> CGSize
//    var layoutPriority: Int { get }
}

public struct SPNeutralLayout: SingleChildLayout, SPSingleChildLayout {
    public func measure(in constraint: SizeConstraint, child: Measurable) -> CGSize {
        child.measure(in: constraint)
    }

    public func layout(size: CGSize, child: Measurable) -> LayoutAttributes {
        LayoutAttributes(size: size)
    }

    public func layout(in context: SPLayoutContext, child: SPLayoutable) -> SPLayoutAttributes {
        SPLayoutAttributes(
            size: child.layout(in: context.proposedSize),
            childPositions: [.zero]
        )
    }
}


class SPLayoutNode: SPLayoutable {
    init(id: ElementIdentifier, element: Element, environment: Environment, cache: CacheTree) {
        self.id = id
        self.element = element
        self.environment = environment
        self.cache = cache
    }

    var id: ElementIdentifier
    var element: Element
    var environment: Environment
    var cache: CacheTree

    var layoutResult: SPSubtreeResult?

    var ensuredResult: SPSubtreeResult {
        guard let layoutResult = layoutResult else {
            fatalError("child was not laid out")
        }
        return layoutResult
    }

    func layout(in proposedSize: CGSize) -> CGSize {
        assert(layoutResult == nil, "layout called twice")

        let result = element.content.singlePassLayout(
            in: SPLayoutContext(proposedSize: proposedSize),
            environment: environment,
            cache: cache
        )
        layoutResult = result

        return result.intermediate.size
    }

}
