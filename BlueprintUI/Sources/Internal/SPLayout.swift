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

public struct ProposedViewSize: Equatable, CustomStringConvertible {

    static let zero = Self(.zero)
    static let infinity = Self(.infinity)

    var width: CGFloat?
    var height: CGFloat?

    init(_ size: CGSize) {
        width = size.width
        height = size.height
    }

    init(width: CGFloat?, height: CGFloat?) {
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

public struct LayoutSubview {
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

    @Storage
    private(set) var placement: Placement?

    var element: Element
    private var content: ElementContent

    var sizable: Sizable { content }
    var environment: Environment

    init(
        element: Element,
        content: ElementContent,
        environment: Environment
    ) {
        self.element = element
        self.content = content
        self.environment = environment
    }

    func place(
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

    func place(
        at position: CGPoint,
        anchor: UnitPoint = .topLeading,
        size: CGSize
    ) {
//        placement = Placement(position: position, anchor: anchor, size: .init(proposal: <#T##ProposedViewSize#>, width: <#T##CGFloat?#>, height: <#T##CGFloat?#>))
        place(at: position, anchor: anchor, proposal: .init(size), width: size.width, height: size.height)
    }

    func sizeThatFits(_ proposal: ProposedViewSize) -> CGSize {
        let size = sizable.sizeThatFits(proposal: proposal, environment: environment)
//        print("\(type(of: element)) measures \(size) within \(proposal)")
        return size
    }
}

protocol Sizable {
    func sizeThatFits(proposal: ProposedViewSize, environment: Environment) -> CGSize
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


