import BlueprintUI
import UIKit

public enum CornerStyle: Equatable {
    case square
    case capsule
    case rounded(radius: CGFloat, corners: Corners = .all)

    public struct Corners: OptionSet, Equatable {
        public let rawValue: UInt8

        public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }

        public static let topLeft = Corners(rawValue: 1)
        public static let topRight = Corners(rawValue: 1 << 1)
        public static let bottomLeft = Corners(rawValue: 1 << 2)
        public static let bottomRight = Corners(rawValue: 1 << 3)

        public static let all: Corners = [.topLeft, .topRight, .bottomLeft, .bottomRight]
        public static let top: Corners = [.topRight, .topLeft]
        public static let left: Corners = [.topLeft, .bottomLeft]
        public static let bottom: Corners = [.bottomLeft, .bottomRight]
        public static let right: Corners = [.topRight, .bottomRight]

        var toCACornerMask: CACornerMask {
            var mask: CACornerMask = []
            if contains(.topLeft) {
                mask.update(with: .layerMinXMinYCorner)
            }

            if contains(.topRight) {
                mask.update(with: .layerMaxXMinYCorner)
            }

            if contains(.bottomLeft) {
                mask.update(with: .layerMinXMaxYCorner)
            }

            if contains(.bottomRight) {
                mask.update(with: .layerMaxXMaxYCorner)
            }
            return mask
        }

        var toUIRectCorner: UIRectCorner {
            var rectCorner: UIRectCorner = []
            if contains(.topLeft) {
                rectCorner.update(with: .topLeft)
            }

            if contains(.topRight) {
                rectCorner.update(with: .topRight)
            }

            if contains(.bottomLeft) {
                rectCorner.update(with: .bottomLeft)
            }

            if contains(.bottomRight) {
                rectCorner.update(with: .bottomRight)
            }
            return rectCorner
        }
    }
}
