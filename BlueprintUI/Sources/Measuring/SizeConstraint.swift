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

    public func maximum(fallback: CGFloat = 0) -> CGSize {
        return CGSize(width: width.constrainedValue ?? fallback, height: height.constrainedValue ?? fallback)
    }

    public func inset(width: CGFloat, height: CGFloat) -> SizeConstraint {
        return SizeConstraint(
            width: self.width - width,
            height: self.height - height
        )
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
        init(_ value: CGFloat) {
            if value == .greatestFiniteMagnitude {
                self = .unconstrained
            } else {
                self = .atMost(value)
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

        /// Adds a scalar value to an Axis. If the Axis is unconstrained the
        /// result will remain unconstrained.
        public static func + (lhs: SizeConstraint.Axis, rhs: CGFloat) -> SizeConstraint.Axis {
            switch lhs {
            case .atMost(let limit):
                return .atMost(limit + rhs)
            case .unconstrained:
                return .unconstrained
            }
        }

        /// Subtracts a scalar value from an Axis. If the Axis is unconstrained
        /// the result will remain unconstrained.
        public static func - (lhs: SizeConstraint.Axis, rhs: CGFloat) -> SizeConstraint.Axis {
            switch lhs {
            case .atMost(let limit):
                return .atMost(limit - rhs)
            case .unconstrained:
                return .unconstrained
            }
        }

        /// Divides an Axis by a scalar value. If the Axis is unconstrained the
        /// result will remain unconstrained.
        public static func / (lhs: SizeConstraint.Axis, rhs: CGFloat) -> SizeConstraint.Axis {
            switch lhs {
            case .atMost(let limit):
                return .atMost(limit / rhs)
            case .unconstrained:
                return .unconstrained
            }
        }

        /// Multiplies an Axis by a scalar value. If the Axis is unconstrained
        /// the result will remain unconstrained.
        public static func * (lhs: SizeConstraint.Axis, rhs: CGFloat) -> SizeConstraint.Axis {
            switch lhs {
            case .atMost(let limit):
                return .atMost(limit * rhs)
            case .unconstrained:
                return .unconstrained
            }
        }

        /// Adds a scalar value to an Axis. If the Axis is unconstrained the
        /// result will remain unconstrained.
        public static func += (lhs: inout SizeConstraint.Axis, rhs: CGFloat) {
            lhs = lhs + rhs
        }

        /// Subtracts a scalar value from an Axis. If the Axis is unconstrained
        /// the result will remain unconstrained.
        public static func -= (lhs: inout SizeConstraint.Axis, rhs: CGFloat) {
            lhs = lhs - rhs
        }

        /// Divides an Axis by a scalar value. If the Axis is unconstrained the
        /// result will remain unconstrained.
        public static func /= (lhs: inout SizeConstraint.Axis, rhs: CGFloat) {
            lhs = lhs / rhs
        }

        /// Multiplies an Axis by a scalar value. If the Axis is unconstrained
        /// the result will remain unconstrained.
        public static func *= (lhs: inout SizeConstraint.Axis, rhs: CGFloat) {
            lhs = lhs * rhs
        }

    }
}
