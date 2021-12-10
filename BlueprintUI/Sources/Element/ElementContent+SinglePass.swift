import Foundation


typealias LayoutResultChildren = [(identifier: ElementIdentifier, node: LayoutResultNode)]


extension ElementContent.Builder {
    func identifiers(in context: SPLayoutContext) -> [ElementIdentifier] {

        var identifierFactory = ElementIdentifier.Factory(elementCount: childCount)

        return children.map { child in
            identifierFactory.nextIdentifier(for: type(of: child.element), key: child.key)
        }
    }

    func singlePassLayout(
        in context: SPLayoutContext,
        environment: Environment,
        cache: CacheTree
    ) -> SPSubtreeResult {

        let identifiers = self.identifiers(in: context)
        let nodes = children.indices.map { (index: Int) -> SPLayoutNode in
            let child = children[index].element
            let id = identifiers[index]
            
            return SPLayoutNode(
                id: id,
                element: child,
                environment: environment,
                cache: cache.subcache(index: index, of: childCount, element: child)
            )
        }

        let intermediateResult = layout.layout(
            in: context,
            children: children.indices.map { (traits: children[$0].traits, layoutable: nodes[$0] ) }
        )

        return SPSubtreeResult(
            intermediate: intermediateResult,
            children: nodes
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

// extending only to pick up Traits
public protocol SPLayout: Layout {
    typealias SPLayoutChild = (traits: Traits, layoutable: SPLayoutable)

    func layout(in context: SPLayoutContext, children: [SPLayoutChild]) -> SPLayoutAttributes
}

public protocol SPLayoutable {
    func layout(in proposedSize: CGSize, options: SPLayoutOptions) -> CGSize
}

extension SPLayoutable {
    func layout(in proposedSize: CGSize) -> CGSize {
        layout(in: proposedSize, options: .default)
    }
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

    private var layoutCount = 0

    var ensuredResult: SPSubtreeResult {
        guard let layoutResult = layoutResult else {
            fatalError("child was not laid out")
        }
        return layoutResult
    }

    func layout(in proposedSize: CGSize, options: SPLayoutOptions) -> CGSize {
        layoutCount += 1
        if layoutCount > options.maxAllowedLayoutCount {
            fatalError("\(type(of: element)) layout called \(layoutCount) times")
        }

        let result = element.content.singlePassLayout(
            in: SPLayoutContext(proposedSize: proposedSize),
            environment: environment,
            cache: cache
        )
        layoutResult = result

        return result.intermediate.size
    }

}

public struct SPLayoutOptions {
    public static let `default` = SPLayoutOptions()

    /// Legacy override to support Stacks
    public var maxAllowedLayoutCount: Int

    /// Legacy override for size constraints and "fill" alignments
    public var sizeOverride: ((CGSize) -> CGSize)

    public init(maxAllowedLayoutCount: Int = 1, sizeOverride: @escaping ((CGSize) -> CGSize) = { $0 }) {
        self.maxAllowedLayoutCount = maxAllowedLayoutCount
        self.sizeOverride = sizeOverride
    }
}
