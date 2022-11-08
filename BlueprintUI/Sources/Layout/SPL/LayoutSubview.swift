import CoreGraphics
import Foundation


public typealias LayoutSubviews = [LayoutSubview]


public struct LayoutSubview {

    typealias SizeCache = SPValueCache<ProposedViewSize, CGSize>

    struct Placement {

        struct Size {
            var proposal: ProposedViewSize
            var width: CGFloat?
            var height: CGFloat?

            static func proposal(_ proposal: ProposedViewSize) -> Self {
                .init(proposal: proposal)
            }
        }

        var position: CGPoint
        var anchor: UnitPoint

        var size: Size

        func origin(for size: CGSize) -> CGPoint {
            position - CGPoint(
                x: size.width * anchor.x,
                y: size.height * anchor.y
            )
        }

        static func filling(frame: CGRect, proposal: ProposedViewSize) -> Self {
            .init(
                position: frame.center,
                anchor: .center,
                size: .init(proposal: proposal, width: frame.width, height: frame.height)
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

    @propertyWrapper
    class Storage<T> {

        var wrappedValue: T?
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

    public subscript<Key>(_ keyType: Key.Type) -> Key.Value where Key: LayoutValueKey {
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

    public func place(
        at frame: CGRect,
        anchor: UnitPoint = .topLeading
    ) {
        place(at: frame.origin, anchor: anchor, size: frame.size)
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
