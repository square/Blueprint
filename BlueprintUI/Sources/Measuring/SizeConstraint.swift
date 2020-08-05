import UIKit

/// Defines the maximum size for a measurement.
///
/// Currently this constraint type can only handles layout where
/// the primary (breaking) axis is horizontal (row in CSS-speak).
public struct SizeConstraint: Hashable {

    /// The width constraint.
    public var width: Axis

    /// The height constraint.
    public var height: Axis

    public init(width: Axis, height: Axis) {
        self.width = width
        self.height = height
    }
}

extension SizeConstraint {

    public static var unconstrained: SizeConstraint {
        return SizeConstraint(width: .unconstrained, height: .unconstrained)
    }

    public init(_ size: CGSize) {
        self.init(width: .atMost(size.width), height: .atMost(size.height))
    }

    public init(width: CGFloat) {
        self.init(width: .atMost(width), height: .unconstrained)
    }

    public init(height: CGFloat) {
        self.init(width: .unconstrained, height: .atMost(height))
    }

    public var minimum: CGSize {
        return CGSize(width: width.minimum, height: height.minimum)
    }

    public var maximum: CGSize {
        return CGSize(width: width.maximum, height: height.maximum)
    }

    public func inset(width: CGFloat, height: CGFloat) -> SizeConstraint {
        return SizeConstraint(
            width: self.width - width,
            height: self.height - height)
    }

}

extension SizeConstraint {

    /// Represents a size constraint for a single axis.
    public enum Axis: Hashable {

        /// The measurement should treat the associated value as the largest
        /// possible size in the given dimension.
        case atMost(CGFloat)

        /// The measurement is unconstrained in the given dimension.
        case unconstrained
        
        /// Creates a `SizeConstraint` with the provided value.
        init(_ value : CGFloat) {
            if value == Axis.maxValue {
                self = .unconstrained
            } else {
                self = .atMost(value)
            }
        }

        /// The maximum magnitude in the given dimension.
        public var maximum: CGFloat {
            switch self {
            case .atMost(let value):
                return value
            case .unconstrained:
                return Axis.maxValue
            }
        }

        /// The minimum magnitude in the given dimension.
        public var minimum: CGFloat {
            switch self {
            case .atMost(_):
                return 0.0
            case .unconstrained:
                return 0.0
            }
        }

        /// The constraint value in this dimension, or `nil` if this dimension is unconstrained.
        public var constrainedValue: CGFloat? {
            switch self {
            case .atMost(let value):
                return value
            case .unconstrained:
                return nil
            }
        }
        
        private static var maxValue : CGFloat = .greatestFiniteMagnitude

        public static func -(lhs: SizeConstraint.Axis, rhs: CGFloat) -> SizeConstraint.Axis {
            switch lhs {
            case .atMost(let limit):
                return .atMost(limit - rhs)
            case .unconstrained:
                return .unconstrained
            }
        }

    }
}
