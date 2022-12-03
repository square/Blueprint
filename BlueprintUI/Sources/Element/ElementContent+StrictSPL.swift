import Foundation

protocol StrictContentStorage {
    func strictLayout(
        in context: StrictLayoutContext,
        environment: Environment
    ) -> StrictSubtreeResult
}

/// SPL version of `Layout`. (Extends `Layout` to pick up `Traits`)
public protocol StrictLayout: Layout {
    typealias StrictLayoutChild = (traits: Traits, layoutable: StrictLayoutable)

    func layout(
        in context: StrictLayoutContext,
        children: [StrictLayoutChild]
    ) -> StrictLayoutAttributes
}

public protocol StrictSingleChildLayout {
    func layout(in context: StrictLayoutContext, child: StrictLayoutable) -> StrictLayoutAttributes
}

public struct StrictLayoutContext: CustomStringConvertible {
    var path: ElementPath
    var cache: StrictCacheNode
    public var proposedSize: SizeConstraint
    public var mode: AxisVarying<StrictPressureMode>

    init(
        path: ElementPath,
        cache: StrictCacheNode,
        proposedSize: SizeConstraint,
        mode: AxisVarying<StrictPressureMode>
    ) {
        self.path = path
        self.cache = cache
        self.proposedSize = proposedSize
        self.mode = mode
    }

    public var description: String {
        "proposed w:\(proposedSize.width) h:\(proposedSize.height), \(mode.horizontal)-\(mode.vertical)"
    }
}

typealias LayoutResultChildren = [(identifier: ElementIdentifier, node: LayoutResultNode)]

struct StrictSubtreeResult {
    var intermediate: StrictLayoutAttributes
    var children: [StrictLayoutNode]

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

    func dump(depth: Int = 0, id: String, position: CGPoint, context: StrictLayoutContext, correction: CGSize) {
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

public enum StrictPressureMode: Equatable, CustomStringConvertible {
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
public struct StrictLayoutAttributes {
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

/// SPL version of `Measurable`
public protocol StrictLayoutable {
    func layout(
        in proposedSize: SizeConstraint,
        options: StrictLayoutOptions
    ) -> CGSize
}

extension StrictLayoutable {
    public func layout(in proposedSize: SizeConstraint) -> CGSize {
        layout(in: proposedSize, options: .default)
    }
}

struct NeutralLayout: StrictSingleChildLayout {
    func layout(in context: StrictLayoutContext, child: StrictLayoutable) -> StrictLayoutAttributes {
        StrictLayoutAttributes(
            size: child.layout(in: context.proposedSize),
            childPositions: [.zero]
        )
    }
}

public struct StrictNeutralLayout: SingleChildLayout {
    public func measure(in constraint: SizeConstraint, child: Measurable) -> CGSize {
        child.measure(in: constraint)
    }

    public func layout(size: CGSize, child: Measurable) -> LayoutAttributes {
        LayoutAttributes(size: size)
    }

    public func sizeThatFits(proposal: SizeConstraint, subview: LayoutSubview) -> CGSize {
        subview.sizeThatFits(proposal)
    }
    
    public func placeSubview(in bounds: CGRect, proposal: SizeConstraint, subview: LayoutSubview) {
    }

    public func layout(in context: StrictLayoutContext, child: StrictLayoutable) -> StrictLayoutAttributes {
        StrictLayoutAttributes(
            size: child.layout(in: context.proposedSize),
            childPositions: [.zero]
        )
    }
}


class StrictLayoutNode: StrictLayoutable {
    init(
        path: ElementPath,
        id: ElementIdentifier,
        element: Element,
        content: ElementContent,
        mode: AxisVarying<StrictPressureMode>,
        environment: Environment,
        cache: StrictCacheNode
    ) {
        self.path = path
        self.id = id
        self.element = element
        self.content = content
        self.mode = mode
        self.environment = environment
        self.cache = cache
    }

    var path: ElementPath
    var id: ElementIdentifier
    var element: Element
    var content: ElementContent
    var mode: AxisVarying<StrictPressureMode>
    var environment: Environment
    var cache: StrictCacheNode

    // These values are initially unset, and captured when the child is laid out:
    var layoutResult: StrictSubtreeResult?
    var proposedSize: SizeConstraint?
    var proposedMode: AxisVarying<StrictPressureMode>?
    var correction: CGSize = .zero
    
    var results: [LayoutResultKey: StrictSubtreeResult] = [:]

    private var layoutCount = 0

    var ensuredResult: StrictSubtreeResult {
        guard let layoutResult = layoutResult else {
            fatalError("child was not laid out")
        }
        return layoutResult
    }

    // saved proposed size, for debugging
    var ensuredProposedSize: SizeConstraint {
        guard let proposedSize = proposedSize else {
            fatalError("child was not laid out")
        }
        return proposedSize
    }

    // effective context, for debugging
    var context: StrictLayoutContext {
        StrictLayoutContext(path: path, cache: cache, proposedSize: ensuredProposedSize, mode: proposedMode!)
    }

    func layout(in proposedSize: SizeConstraint, options: StrictLayoutOptions) -> CGSize {

        let layoutMode = AxisVarying(
            horizontal: options.mode.horizontal ?? mode.horizontal,
            vertical: options.mode.vertical ?? mode.vertical
        )

        let path = path.appending(identifier: id)

        let resultKey = LayoutResultKey(proposedSize: proposedSize, proposedMode: layoutMode)
        if let layoutResult = results[resultKey] {
            self.proposedSize = proposedSize
            self.proposedMode = layoutMode
            self.layoutResult = layoutResult
            
            Logger.logCacheHit(object: self, description: "\(path)", constraint: proposedSize)

            return layoutResult.intermediate.size
        }
        
        Logger.logCacheMiss(object: self, description: "\(path)", constraint: proposedSize)
        
        // TODO: this is not enforceable with cached layout nodes -- elements nested within
        // multiple stacks will get hit (2 * stack depth) times. We can disable it entirely, or
        // try to track this some other way.
        layoutCount += 1
        if layoutCount > options.maxAllowedLayoutCount {
//            print("warning: \(path) layout called \(layoutCount) times")
//            fatalError("\(type(of: element)) layout called \(layoutCount) times")
        }

//        var environment = environment
//        if let debugElementPath = environment.debugElementPath, path.matches(expression: debugElementPath) {
//            print("Debugging triggered for path \(path)")
//            environment.debugElementPath = nil
//        }
        
        Logger.logMeasureStart(object: self, description: "\(path)", constraint: proposedSize)

        var layoutResult = content.performStrictLayout(
            in: StrictLayoutContext(
                path: path,
                cache: cache,
                proposedSize: proposedSize,
                mode: layoutMode
            ),
            environment: environment
        )

        // Apply size overrides when we are in fill mode.
        if layoutMode.horizontal == .fill, let width = proposedSize.width.constrainedValue {
            let oldWidth = layoutResult.intermediate.size.width
            if oldWidth != width {
//                print("Applying width override to \(type(of: element)), \(oldWidth) -> \(width)")
                correction.width = width - oldWidth
                layoutResult.intermediate.size.width = width
            }
        }
        if layoutMode.vertical == .fill, let height = proposedSize.height.constrainedValue {
            let oldHeight = layoutResult.intermediate.size.height
            if oldHeight != height {
//                print("Applying height override to \(type(of: element)), \(oldHeight) -> \(height)")
                correction.height = height - oldHeight
                layoutResult.intermediate.size.height = height
            }
        }
        
        Logger.logMeasureEnd(object: self)

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
        
        results[resultKey] = layoutResult

        return layoutResult.intermediate.size
    }
    
    
    struct LayoutResultKey: Hashable {
        var proposedSize: SizeConstraint
        var proposedMode: AxisVarying<StrictPressureMode>
    }

}

protocol StrictCacheTreeKey {
    associatedtype Value
}

final class StrictCacheTree<SubcacheKey> where SubcacheKey: Hashable {

    typealias Subcache = StrictCacheTree<SubcacheKey>

    private var caches: [ObjectIdentifier: Any] = [:]
    private var subcaches: [SubcacheKey: Subcache] = [:]

    var path: String

    init(path: String? = nil) {
        let path = path ?? ""
        self.path = path
    }

    func get<Key>(keyType: Key.Type, or create: () -> Key.Value) -> Key.Value where Key: StrictCacheTreeKey {
        let key = ObjectIdentifier(keyType)
        if let value = caches[key] as? Key.Value {
            return value
        }
        let value = create()
        caches[key] = value
        return value
    }

    func subcache(key: SubcacheKey) -> Subcache {
        if let subcache = subcaches[key] {
            return subcache
        }
        let subcache = Subcache(path: path + "/" + String(describing: key))
        subcaches[key] = subcache
        return subcache
    }
}

typealias StrictCacheNode = StrictCacheTree<Int>

/// Enables legacy behavior, and "top-down" cascading effects
public struct StrictLayoutOptions {
    public static let `default` = StrictLayoutOptions()

    /// Legacy override to support Stacks
    public var maxAllowedLayoutCount: Int

    /// Legacy override for size constraints and "fill" alignments
    public var mode: AxisVarying<StrictPressureMode?>

    public init(
        maxAllowedLayoutCount: Int = 1,
        mode: AxisVarying<StrictPressureMode?> = AxisVarying(horizontal: nil, vertical: nil)
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

extension AxisVarying: Hashable, Equatable where T: Hashable { }

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
