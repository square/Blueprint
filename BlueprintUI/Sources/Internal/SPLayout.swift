import CoreGraphics
import UIKit

public protocol SPLayout {
    typealias Subviews = LayoutSubviews

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews
    ) -> CGSize

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews
    )
}

public struct ProposedViewSize: Hashable, CustomStringConvertible {

    public static let zero = Self(.zero)
    public static let infinity = Self(.infinity)
    public static let unspecified = Self(width: nil, height: nil)

    public var width: CGFloat?
    public var height: CGFloat?

    public init(_ size: CGSize) {
        width = size.width
        height = size.height
    }

    public init(width: CGFloat?, height: CGFloat?) {
        self.width = width
        self.height = height
    }

    func replacingUnspecifiedDimensions(
        by size: CGSize = CGSize(width: 10, height: 10)
    ) -> CGSize {
        CGSize(width: width ?? size.width, height: height ?? size.height)
    }

    public var description: String {
        "(\(width?.description ?? "nil"), \(height?.description ?? "nil"))"
    }
}

public typealias LayoutSubviews = [LayoutSubview]

protocol LayoutValueKey {
    associatedtype Value
    static var defaultValue: Value { get }
}

public struct LayoutSubview {
    typealias SizeCache = SPValueCache<ProposedViewSize, CGSize>

    struct Placement {
        var position: CGPoint
        var anchor: UnitPoint

        struct Size {
            var proposal: ProposedViewSize
            var width: CGFloat?
            var height: CGFloat?

            static func proposal(_ proposal: ProposedViewSize) -> Self {
                .init(proposal: proposal)
            }
        }

        var size: Size
//        var proposal: ProposedViewSize
//        var size: CGSize?

        func origin(for size: CGSize) -> CGPoint {
            position - CGPoint(
                x: size.width * anchor.x,
                y: size.height * anchor.y
            )
        }
    }

    class Attributes {

        /// Corresponds to `UIView.layer.transform`.
        var transform: CATransform3D = CATransform3DIdentity

        /// Corresponds to `UIView.alpha`.
        var alpha: CGFloat = 1

        /// Corresponds to `UIView.isUserInteractionEnabled`.
        var isUserInteractionEnabled: Bool = true

        /// Corresponds to `UIView.isHidden`.
        var isHidden: Bool = false
    }

    @Storage
    private(set) var placement: Placement?

    private var sizeCache: SizeCache { measureContext.cache.valueCache }

    var element: Element
    private var content: ElementContent

    var sizable: Sizable { content }
    var environment: Environment { measureContext.environment }
    var cache: SPCacheNode { measureContext.cache }

    var measureContext: MeasureContext

    var layoutValues: [ObjectIdentifier: Any] = [:]

    var attributes: Attributes = .init()

    init<Key: LayoutValueKey>(
        element: Element,
        content: ElementContent,
        measureContext: MeasureContext,
        key: Key.Type,
        value: Key.Value
    ) {
        self.element = element
        self.content = content
        self.measureContext = measureContext
        layoutValues = [ObjectIdentifier(key): value]
    }

    init<LayoutType: Layout>(
        element: Element,
        content: ElementContent,
        measureContext: MeasureContext,
        traits: LayoutType.Traits,
        type: LayoutType.Type = LayoutType.self
    ) {
        self.element = element
        self.content = content
        self.measureContext = measureContext
        layoutValues = [
            ObjectIdentifier(GenericLayoutValueKey<LayoutType>.self): traits,
        ]
    }

    subscript<Key>(_ keyType: Key.Type) -> Key.Value where Key: LayoutValueKey {
        if let value = layoutValues[ObjectIdentifier(keyType)] as? Key.Value {
            return value
        }
        return keyType.defaultValue
    }

    public func place(
        at position: CGPoint,
        anchor: UnitPoint = .topLeading,
        proposal: ProposedViewSize,
        width: CGFloat? = nil,
        height: CGFloat? = nil
    ) {
        placement = Placement(
            position: position,
            anchor: anchor,
            size: .init(proposal: proposal, width: width, height: height)
        )
    }

    public func place(
        at position: CGPoint,
        anchor: UnitPoint = .topLeading,
        size: CGSize
    ) {
        place(at: position, anchor: anchor, proposal: .init(size), width: size.width, height: size.height)
    }

    public func sizeThatFits(_ proposal: ProposedViewSize) -> CGSize {
        sizeCache.get(key: proposal) { proposal in
            sizable.sizeThatFits(proposal: proposal, context: .init(
                cache: cache,
                environment: environment
            ))
        }
    }
}

protocol Sizable {
    func sizeThatFits(proposal: ProposedViewSize, context: MeasureContext) -> CGSize
}

@propertyWrapper
class Storage<T> {
    var wrappedValue: T?
}

extension CGSize {
    static let infinity = Self(width: CGFloat.infinity, height: CGFloat.infinity)
}

extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}

public struct UnitPoint: Hashable {

    public var x: CGFloat
    public var y: CGFloat

    @inlinable public init() {
        self.init(x: 0, y: 0)
    }

    @inlinable public init(x: CGFloat, y: CGFloat) {
        self.x = x
        self.y = y
    }

    public static let zero: UnitPoint = .init(x: 0, y: 0)

    public static let center: UnitPoint = .init(x: 0.5, y: 0.5)

    public static let leading: UnitPoint = .init(x: 0, y: 0.5)

    public static let trailing: UnitPoint = .init(x: 1, y: 0.5)

    public static let top: UnitPoint = .init(x: 0.5, y: 0)

    public static let bottom: UnitPoint = .init(x: 0.5, y: 1)

    public static let topLeading: UnitPoint = .init(x: 0, y: 0)

    public static let topTrailing: UnitPoint = .init(x: 1, y: 0)

    public static let bottomLeading: UnitPoint = .init(x: 0, y: 1)

    public static let bottomTrailing: UnitPoint = .init(x: 1, y: 1)
}

struct Padding: SPLayout {
    var insets: UIEdgeInsets

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews) -> CGSize {
        assert(subviews.count == 1)
        let insetSize = CGSize(
            width: insets.left + insets.right,
            height: insets.top + insets.bottom
        )
        let insetProposal = ProposedViewSize(
            width: proposal.width.map { $0 - insetSize.width },
            height: proposal.height.map { $0 - insetSize.height }
        )
        let childSize = subviews[0].sizeThatFits(insetProposal)
        return childSize + insetSize
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews) {
        assert(subviews.count == 1)
        subviews[0].place(at: bounds.center, anchor: .center, proposal: proposal)
    }
}


