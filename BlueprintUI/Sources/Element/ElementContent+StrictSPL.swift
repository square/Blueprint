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
    var children: [StrictProposalCaptureNode]

    func resolve() -> LayoutResultChildren {
        zip(intermediate.childPositions, children).map { position, node in

            let proposal = node.lastProposal!

            let layoutNode = node.layoutNode
            let subtreeResult = layoutNode.results[proposal]!
            let childSize = subtreeResult.intermediate.size
            let childFrame = CGRect(
                origin: position,
                size: childSize
            )
            let nodeAttributes = LayoutAttributes(frame: childFrame)
            let result = LayoutResultNode(
                element: layoutNode.element,
                layoutAttributes: nodeAttributes,
                environment: layoutNode.environment,
                children: subtreeResult.resolve()
            )

            return (layoutNode.id, result)
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
            let proposal = child.lastProposal!
            let result = child.layoutNode.results[proposal]!
            result.dump(
                depth: depth + 1,
                id: "\(child.layoutNode.id)",
                position: childPosition,
                context: StrictLayoutContext(
                    path: context.path.appending(identifier:  child.layoutNode.id),
                    cache: child.layoutNode.cache,
                    proposedSize: proposal.proposedSize,
                    mode: proposal.proposedMode
                ),
                correction: child.layoutNode.correction
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
public struct StrictLayoutAttributes: Equatable {
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

extension CATransform3D: Equatable {
    public static func == (lhs: CATransform3D, rhs: CATransform3D) -> Bool {
        CATransform3DEqualToTransform(lhs, rhs)
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

    public func placeSubview(in bounds: CGRect, proposal: SizeConstraint, subview: LayoutSubview) {}

    public func layout(in context: StrictLayoutContext, child: StrictLayoutable) -> StrictLayoutAttributes {
        StrictLayoutAttributes(
            size: child.layout(in: context.proposedSize),
            childPositions: [.zero]
        )
    }
}


class StrictProposalCaptureNode: StrictLayoutable {
    let contextMode: AxisVarying<StrictPressureMode>
    let layoutNode: StrictLayoutNode
    
    var lastProposal: StrictLayoutResultKey?
    
    init(
        mode: AxisVarying<StrictPressureMode>,
        layoutNode: StrictLayoutNode
    ) {
        self.contextMode = mode
        self.layoutNode = layoutNode
    }
    
    func layout(in proposedSize: SizeConstraint, options: StrictLayoutOptions) -> CGSize {
        
        let layoutMode = AxisVarying(
            horizontal: options.mode.horizontal ?? contextMode.horizontal,
            vertical: options.mode.vertical ?? contextMode.vertical
        )

        let proposal = StrictLayoutResultKey(
            proposedSize: proposedSize,
            proposedMode: layoutMode
        )

        lastProposal = proposal

        return layoutNode.layout(in: proposedSize, mode: layoutMode)
    }
}

class StrictLayoutNode {
    init(
        path: ElementPath,
        id: ElementIdentifier,
        element: Element,
        content: ElementContent,
        environment: Environment,
        cache: StrictCacheNode
    ) {
        self.path = path
        self.id = id
        self.element = element
        self.content = content
        self.environment = environment
        self.cache = cache

        fullPath = path.appending(identifier: id)
    }

    var path: ElementPath
    var id: ElementIdentifier
    var element: Element
    var content: ElementContent
    var environment: Environment
    var cache: StrictCacheNode

    var fullPath: ElementPath

    var correction: CGSize = .zero

    var results: [LayoutResultKey: StrictSubtreeResult] = [:]

    private var layoutCount = 0
    
    func result(in proposedSize: SizeConstraint, mode: AxisVarying<StrictPressureMode>) -> StrictSubtreeResult {
        results[LayoutResultKey(proposedSize: proposedSize, proposedMode: mode)]!
    }

    func layout(in proposedSize: SizeConstraint, mode: AxisVarying<StrictPressureMode>) -> CGSize {

        let layoutMode = mode

        let resultKey = LayoutResultKey(proposedSize: proposedSize, proposedMode: layoutMode)

        if let layoutResult = results[resultKey] {

            Logger.logCacheHit(object: self, description: "\(fullPath)", constraint: proposedSize)

            return layoutResult.intermediate.size
        }

        Logger.logCacheMiss(object: self, description: "\(fullPath)", constraint: proposedSize)

        // TODO: this is not enforceable with cached layout nodes -- elements nested within
        // multiple stacks will get hit (2 * stack depth) times. We can disable it entirely, or
        // try to track this some other way.
        layoutCount += 1
//        if layoutCount > options.maxAllowedLayoutCount {
//            print("warning: \(path) layout called \(layoutCount) times")
//            fatalError("\(type(of: element)) layout called \(layoutCount) times")
//        }

        var environment = environment
        if let debugElementPath = environment.debugElementPath, fullPath.matches(expression: debugElementPath) {
            print("Debugging triggered for path \(fullPath)")
            environment.debugElementPath = nil
        }

        Logger.logMeasureStart(object: self, description: "\(fullPath)", constraint: proposedSize)

        var layoutResult = content.performStrictLayout(
            in: StrictLayoutContext(
                path: fullPath,
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

    typealias LayoutResultKey = StrictLayoutResultKey

    func dump(depth: Int = 0) {
        let indent = String(repeating: "  ", count: depth)
        
        print("\(indent)- \(id)")
//        print("\(indent)    \(context)")

        for (resultKey, resultValue) in results {
            print("\(indent)    * (\(resultKey.proposedMode), \(resultKey.proposedSize)): \(resultValue.intermediate.size)")
            for child in resultValue.children {
                child.layoutNode.dump(depth: depth + 1)
            }
        }
    }
}

struct StrictLayoutResultKey: Hashable {
    var proposedSize: SizeConstraint
    var proposedMode: AxisVarying<StrictPressureMode>
}

enum Unit: Hashable {
    case value
}

protocol StrictCacheTreeEntry {
    associatedtype Key: Hashable = Unit
    associatedtype Value
}

final class StrictCacheTree<SubcacheKey> where SubcacheKey: Hashable {

    typealias Subcache = StrictCacheTree<SubcacheKey>

    private var caches: [CacheKey: Any] = [:]
    private var subcaches: [SubcacheKey: Subcache] = [:]

    var path: String

    init(path: String? = nil) {
        let path = path ?? ""
        self.path = path
    }

    struct CacheKey: Hashable {
        var entryType: ObjectIdentifier
        var entryKey: AnyHashable
    }

    func get<Entry>(
        entryType: Entry.Type,
        key: Entry.Key,
        or create: () -> Entry.Value
    ) -> Entry.Value where Entry: StrictCacheTreeEntry {
        let key = CacheKey(entryType: ObjectIdentifier(entryType), entryKey: key)
        if let value = caches[key] as? Entry.Value {
            return value
        }
        let value = create()
        caches[key] = value
        return value
    }

    func get<Entry>(
        entryType: Entry.Type,
        or create: () -> Entry.Value
    ) -> Entry.Value where Entry: StrictCacheTreeEntry, Entry.Key == Unit {
        get(entryType: entryType, key: .value, or: create)
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

extension AxisVarying: Hashable, Equatable where T: Hashable {}

extension AxisVarying: CustomStringConvertible {
    public var description: String {
        "\(horizontal)-\(vertical)"
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

extension Element {
    public func debugPath(_ path: String) -> Element {
        adaptedEnvironment(keyPath: \.debugElementPath, value: path)
    }
}
