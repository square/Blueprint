import UIKit

/// Defines the maximum size for a measurement.
///
/// Currently this constraint type can only handles layout where
/// the primary (breaking) axis is horizontal (row in CSS-speak).
public struct SizeConstraint: Hashable, CustomDebugStringConvertible {

    /// The width constraint.
    @UnconstrainedInfiniteAxis
    public var width: Axis

    /// The height constraint.
    @UnconstrainedInfiniteAxis
    public var height: Axis

    public init(width: Axis, height: Axis) {
        self.width = width
        self.height = height
    }

    // MARK: CustomDebugStringConvertible

    public var debugDescription: String {
        "<SizeConstraint: \(width.debugDescription) x \(height.debugDescription)>"
    }

    var proposedViewSize: ProposedViewSize {
        ProposedViewSize(
            width: _width.correctedAxis.proposedViewSizeAxis,
            height: _height.correctedAxis.proposedViewSizeAxis
        )
    }
}

extension SizeConstraint {

    public static var unconstrained: SizeConstraint {
        SizeConstraint(width: .unconstrained, height: .unconstrained)
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
        CGSize(width: width.minimum, height: height.minimum)
    }

    public var maximum: CGSize {
        CGSize(width: width.maximum, height: height.maximum)
    }

    public func inset(width: CGFloat, height: CGFloat) -> SizeConstraint {
        SizeConstraint(
            width: self.width - width,
            height: self.height - height
        )
    }

}

extension SizeConstraint {

    /// Represents a size constraint for a single axis.
    public enum Axis: Hashable, CustomDebugStringConvertible {

        /// The measurement should treat the associated value as the largest
        /// possible size in the given dimension.
        case atMost(CGFloat)

        /// The measurement is unconstrained in the given dimension.
        case unconstrained

        /// Creates a `SizeConstraint` with the provided value.
        init(_ value: CGFloat) {
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

        private static var maxValue: CGFloat = .greatestFiniteMagnitude

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

        /// If the `Axis` is greater than zero.
        public var isGreaterThanZero: Bool {
            switch self {
            case .atMost(let limit):
                return limit > 0
            case .unconstrained:
                return true
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

        // MARK: CustomDebugStringConvertible

        public var debugDescription: String {
            switch self {
            case .atMost(let max):
                return "atMost(\(max))"
            case .unconstrained:
                return "unconstrained"
            }
        }
    }
}

extension SizeConstraint.Axis: CustomStringConvertible {
    public var description: String {
        switch self {
        case .atMost(let max):
            return "\(max)"
        case .unconstrained:
            return "unc"
        }
    }
}

extension SizeConstraint: CustomStringConvertible {
    public var description: String {
        "(\(width) \(height))"
    }
}

extension SizeConstraint {
    /// This property wrapper checks the value of `atMost` cases, and turns it into an
    /// `unconstrained` axis if the value equals `greatestFiniteMagnitude` or `isInfinite`.
    @propertyWrapper public struct UnconstrainedInfiniteAxis: Equatable, Hashable {

        enum CorrectedAxis: Equatable, Hashable {
            case atMost(CGFloat)
            case unconstrained
            case infinite
            case greatestFiniteMagnitude

            var axis: Axis {
                switch self {
                case .atMost(let value):
                    return .atMost(value)

                case .unconstrained, .infinite, .greatestFiniteMagnitude:
                    return .unconstrained
                }
            }

            var proposedViewSizeAxis: CGFloat? {
                switch self {
                case .atMost(let value):
                    return value

                case .unconstrained:
                    return nil

                case .infinite:
                    return .infinity

                case .greatestFiniteMagnitude:
                    return .greatestFiniteMagnitude
                }
            }

            // Equatability based on the implementation before `ProposedViewSize` support was added.
            static func == (_ lhs: Self, _ rhs: Self) -> Bool {
                lhs.axisValue == rhs.axisValue
            }

            // Hashability based on the implementation before `ProposedViewSize` support was added.
            func hash(into hasher: inout Hasher) {
                hasher.combine(axisValue)
            }

            /// A value that represents the `Equatable`/`Hashable` behavior before `ProposedViewSize` support was added.
            private var axisValue: CGFloat? {
                switch self {
                case .atMost(let value):
                    return value

                case .unconstrained, .infinite, .greatestFiniteMagnitude:
                    return nil
                }
            }
        }

        var correctedAxis: CorrectedAxis

        public var wrappedValue: Axis {
            get { correctedAxis.axis }
            set { correctedAxis = Self.correctedAxis(for: newValue) }
        }

        public init(wrappedValue value: Axis) {
            correctedAxis = Self.correctedAxis(for: value)
        }

        private static func correctedAxis(for axis: Axis) -> CorrectedAxis {
            switch axis {
            case .atMost(let maxAxis):
                if maxAxis.isInfinite {
                    return .infinite
                } else if maxAxis == .greatestFiniteMagnitude {
                    return .greatestFiniteMagnitude
                } else {
                    return .atMost(maxAxis)
                }
            case .unconstrained:
                return .unconstrained
            }
        }
    }
}
