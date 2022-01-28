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
                path: context.path,
                id: id,
                element: child,
                mode: context.mode,
                environment: environment,
                cache: cache.subcache(index: index, of: childCount, element: child)
            )
        }

        let intermediateResult = layout.layout(
            in: context,
            children: children.indices.map { (traits: children[$0].traits, layoutable: nodes[$0]) }
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
            path: context.path,
            id: identifier,
            element: child,
            mode: context.mode,
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
            path: context.path,
            id: identifier,
            element: child,
            mode: context.mode,
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
                childPositions: []
            ),
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

    func dump(depth: Int = 0, id: String, position: CGPoint, context: SPLayoutContext, correction: CGSize) {
        let size = "w:\(intermediate.size.width) h:\(intermediate.size.height)"

        let indent = String(repeating: "  ", count: depth)
        let origin = "x:\(position.x) y:\(position.y)"

        print("\(indent)- \(id)")
        print("\(indent)    \(context)")
        print("\(indent)    resolved \(origin) \(size)")

        if correction.width != 0 {
            print("\(indent)    corrected width from \(intermediate.size.width - correction.width)")
        }
        if correction.height != 0 {
            print("\(indent)    corrected height from \(intermediate.size.height - correction.height)")
        }

        for (child, childPosition) in zip(children, intermediate.childPositions) {
            child.ensuredResult.dump(
                depth: depth+1,
                id: "\(child.id)",
                position: childPosition,
                context: child.context,
                correction: child.correction
            )
        }
    }

}

public struct SPLayoutContext: CustomStringConvertible {
    public var path: ElementPath
    public var proposedSize: CGSize
    public var mode: AxisVarying<SPPressureMode>

    public init(
        path: ElementPath,
        proposedSize: CGSize,
        mode: AxisVarying<SPPressureMode>
    ) {
        self.path = path
        self.proposedSize = proposedSize
        self.mode = mode
    }

    public var description: String {
        "proposed w:\(proposedSize.width) h:\(proposedSize.height), \(mode.horizontal)-\(mode.vertical)"
    }
}

public enum SPPressureMode: Equatable, CustomStringConvertible {
    case natural
    case fill

    public var description: String {
        switch self {
        case .natural: return "natural"
        case .fill: return "fill"
        }
    }
}


/// SPL version of `LayoutAttributes`.
public struct SPLayoutAttributes {
    public var size: CGSize
    public var childPositions: [CGPoint]

    public var isUserInteractionEnabled: Bool = true
    public var isHidden: Bool = false
    public var transform: CATransform3D = CATransform3DIdentity
    public var alpha: CGFloat = 1.0

    public init(size: CGSize, childPositions: [CGPoint] = []) {
        self.size = size
        self.childPositions = childPositions
    }
}

/// SPL version of `Layout`. (Extends `Layout` to pick up `Traits`)
public protocol SPLayout: Layout {
    typealias SPLayoutChild = (traits: Traits, layoutable: SPLayoutable)

    func layout(
        in context: SPLayoutContext, 
        children: [SPLayoutChild]
    ) -> SPLayoutAttributes
}

/// SPL version of `Measurable`
public protocol SPLayoutable {
    func layout(
        in proposedSize: CGSize, 
        options: SPLayoutOptions
    ) -> CGSize
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
    init(
        path: ElementPath,
        id: ElementIdentifier,
        element: Element,
        mode: AxisVarying<SPPressureMode>,
        environment: Environment,
        cache: CacheTree
    ) {
        self.path = path
        self.id = id
        self.element = element
        self.mode = mode
        self.environment = environment
        self.cache = cache
    }

    var path: ElementPath
    var id: ElementIdentifier
    var element: Element
    var mode: AxisVarying<SPPressureMode>
    var environment: Environment
    var cache: CacheTree

    // These values are initially unset, and captured when the child is laid out:
    var layoutResult: SPSubtreeResult?
    var proposedSize: CGSize?
    var proposedMode: AxisVarying<SPPressureMode>?
    var correction: CGSize = .zero

    private var layoutCount = 0

    var ensuredResult: SPSubtreeResult {
        guard let layoutResult = layoutResult else {
            fatalError("child was not laid out")
        }
        return layoutResult
    }

    // saved proposed size, for debugging
    var ensuredProposedSize: CGSize {
        guard let proposedSize = proposedSize else {
            fatalError("child was not laid out")
        }
        return proposedSize
    }

    // effective context, for debugging
    var context: SPLayoutContext {
        SPLayoutContext(path: path, proposedSize: ensuredProposedSize, mode: proposedMode!)
    }

    func layout(in proposedSize: CGSize, options: SPLayoutOptions) -> CGSize {
        layoutCount += 1
        if layoutCount > options.maxAllowedLayoutCount {
            fatalError("\(type(of: element)) layout called \(layoutCount) times")
        }

        let layoutMode = AxisVarying(
            horizontal: options.mode.horizontal ?? mode.horizontal,
            vertical: options.mode.vertical ?? mode.vertical
        )

        precondition(
            proposedSize.width != .greatestFiniteMagnitude && proposedSize.height != .greatestFiniteMagnitude,
            "GFM detected"
        )

        var environment = environment
        let path = path.appending(identifier: id)

        if let debugElementPath = environment.debugElementPath, path.matches(expression: debugElementPath) {
            print("Debugging triggered for path \(path)")
            environment.debugElementPath = nil
        }

        var layoutResult = element.content.singlePassLayout(
            in: SPLayoutContext(
                path: path,
                proposedSize: proposedSize,
                mode: layoutMode
            ),
            environment: environment,
            cache: cache
        )

        // Apply size overrides when we are in fill mode.

        if layoutMode.horizontal == .fill, let width = proposedSize.finiteWidth {
            let oldWidth = layoutResult.intermediate.size.width
            if oldWidth != width {
                print("Applying width override to \(type(of: element)), \(oldWidth) -> \(width)")
                correction.width = width - oldWidth
                layoutResult.intermediate.size.width = width
            }
        }
        if layoutMode.vertical == .fill, let height = proposedSize.finiteHeight {
            let oldHeight = layoutResult.intermediate.size.height
            if oldHeight != height {
                print("Applying height override to \(type(of: element)), \(oldHeight) -> \(height)")
                correction.height = height - oldHeight
                layoutResult.intermediate.size.height = height
            }
        }

        self.proposedSize = proposedSize
        self.proposedMode = layoutMode
        self.layoutResult = layoutResult

        assert(
            layoutResult.intermediate.size.isFinite,
            "\(type(of: element)) layout size must be finite"
        )

        assert(
            layoutResult.intermediate.childPositions.allSatisfy { $0.isFinite },
            "\(type(of: element)) child positions must be finite"
        )

        return layoutResult.intermediate.size
    }

}

/// Enables legacy behavior, and "top-down" cascading effects
public struct SPLayoutOptions {
    public static let `default` = SPLayoutOptions()

    /// Legacy override to support Stacks
    public var maxAllowedLayoutCount: Int

    /// Legacy override for size constraints and "fill" alignments
    public var mode: AxisVarying<SPPressureMode?>

    public init(
        maxAllowedLayoutCount: Int = 1,
        mode: AxisVarying<SPPressureMode?> = AxisVarying(horizontal: nil, vertical: nil)
    ) {
        self.maxAllowedLayoutCount = maxAllowedLayoutCount
        self.mode = mode
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

public enum DebugElementPathKey: EnvironmentKey {
    public static let defaultValue: String? = nil
}

extension Environment {
    public var debugElementPath: String? {
        get { self[DebugElementPathKey.self] }
        set { self[DebugElementPathKey.self] = newValue }
    }
}

extension ElementPath {
    func matches(expression: String) -> Bool {
        "\(self)".range(of: expression, options: .regularExpression) != nil
    }
}
