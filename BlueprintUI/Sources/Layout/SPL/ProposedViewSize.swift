import CoreGraphics
import Foundation


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

    public func replacingUnspecifiedDimensions(
        by size: CGSize = CGSize(width: 10, height: 10)
    ) -> CGSize {
        CGSize(width: width ?? size.width, height: height ?? size.height)
    }

    public var description: String {
        "(\(width?.description ?? "nil"), \(height?.description ?? "nil"))"
    }
}


extension ProposedViewSize {

    public init(_ sizeConstraint: SizeConstraint) {
        self = sizeConstraint.proposedViewSize
    }
}


extension SizeConstraint {

    public init(_ proposal: ProposedViewSize) {
        self.init(
            width: .init(singlePassProposal: proposal.width),
            height: .init(singlePassProposal: proposal.height)
        )
    }
}


extension SizeConstraint.Axis {

    public init(singlePassProposal: CGFloat?) {
        if let singlePassProposal = singlePassProposal {
            self = .atMost(singlePassProposal)
        } else {
            self = .unconstrained
        }
    }
}
