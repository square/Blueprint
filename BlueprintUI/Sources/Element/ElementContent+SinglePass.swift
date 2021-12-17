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
                context: context,
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

        let node = SPLayoutNode(
            id: identifier,
            element: child,
            context: context,
            environment: environment,
            cache: cache
        )

        return SPSubtreeResult(
            intermediate: NeutralLayout().layout(in: context, child: node),
            children: [node]
        )
    }
}

extension LazyStorage {
    func singlePassLayout(
        in context: SPLayoutContext,
        environment: Environment,
        cache: CacheTree
    ) -> SPSubtreeResult {
        let child = buildChild(in: .init(context.proposedSize), environment: environment, cache: cache.outOfBandCache)
        let identifier = ElementIdentifier(elementType: type(of: child), key: nil, count: 1)
        let cache = cache.subcache(element: child)

        let node = SPLayoutNode(
            id: identifier,
            element: child,
            context: context,
            environment: environment,
            cache: cache
        )

        return SPSubtreeResult(
            intermediate: NeutralLayout().layout(in: context, child: node),
            children: [node]
        )
    }
}

struct NeutralLayout: SPSingleChildLayout {
    func layout(in context: SPLayoutContext, child: SPLayoutable) -> SPLayoutAttributes {
        SPLayoutAttributes(
            size: child.layout(in: context.proposedSize),
            childPositions: [.zero]
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

    public var proposedSize: CGSize

    public var mode: AxisVarying<SPLayoutMode>

    public init(
        proposedSize: CGSize,
        mode: AxisVarying<SPLayoutMode> // = .init(horizontal: .natural, vertical: .natural)
    ) {
        self.proposedSize = proposedSize
        self.mode = mode
    }
}

public enum SPLayoutMode: Equatable, CustomStringConvertible {
    case natural
    case fill

    public var description: String {
        switch self {
        case .natural: return "natural"
        case .fill: return "fill"
        }
    }
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
    public func layout(in proposedSize: CGSize) -> CGSize {
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
    init(id: ElementIdentifier, element: Element, context: SPLayoutContext, environment: Environment, cache: CacheTree) {
        self.id = id
        self.element = element
        self.context = context
        self.environment = environment
        self.cache = cache
    }

    var id: ElementIdentifier
    var element: Element
    var context: SPLayoutContext
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

        let layoutMode = AxisVarying(
            horizontal: options.mode.horizontal ?? context.mode.horizontal,
            vertical: options.mode.vertical ?? context.mode.vertical
        )


//        print("\(type(of: element)) h:\(layoutMode.horizontal) v:\(layoutMode.vertical)")

        var result = element.content.singlePassLayout(
            in: SPLayoutContext(
                proposedSize: proposedSize,
                mode: layoutMode
            ),
            environment: environment,
            cache: cache
        )

        if layoutMode.horizontal == .fill, let width = proposedSize.finiteWidth {
            let oldWidth = result.intermediate.size.width
//            print("Applying width override to \(type(of: element)), \(oldWidth) -> \(width)")
            result.intermediate.size.width = width
        } else {
//            print("Not applying width to \(type(of: element))")
        }
        if layoutMode.vertical == .fill, let height = proposedSize.finiteHeight {
            let oldHeight = result.intermediate.size.height
//            print("Applying height override to \(type(of: element)), \(oldHeight) -> \(height)")
            result.intermediate.size.height = height
        }

        layoutResult = result

        assert(
            result.intermediate.size.isFinite,
            "\(type(of: element)) layout size must be finite"
        )

        assert(
            result.intermediate.childPositions.allSatisfy { $0.isFinite },
            "\(type(of: element)) child positions must be finite"
        )

        return result.intermediate.size
    }

}

public struct SPLayoutOptions {
    public static let `default` = SPLayoutOptions()

    /// Legacy override to support Stacks
    public var maxAllowedLayoutCount: Int

    /// Legacy override for size constraints and "fill" alignments
//    public var sizeOverride: ((CGSize) -> CGSize)
    public var mode: AxisVarying<SPLayoutMode?>

    public init(
        maxAllowedLayoutCount: Int = 1,
        mode: AxisVarying<SPLayoutMode?> = AxisVarying(horizontal: nil, vertical: nil)
//        sizeOverride: @escaping ((CGSize) -> CGSize) = { $0 }
    ) {
        self.maxAllowedLayoutCount = maxAllowedLayoutCount
        self.mode = mode
//        self.sizeOverride = sizeOverride
    }
}

public struct AxisVarying<T> {
    public var horizontal: T
    public var vertical: T

    public init(horizontal: T, vertical: T) {
        self.horizontal = horizontal
        self.vertical = vertical
    }
}

extension CGFloat {
    var finiteValue: CGFloat? {
        isFinite ? self : nil
    }
}

extension CGSize {
    var finiteWidth: CGFloat? {
        width.finiteValue
    }

    var finiteHeight: CGFloat? {
        height.finiteValue
    }
}
