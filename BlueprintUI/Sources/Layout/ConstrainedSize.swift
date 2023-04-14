import UIKit

/// Constrains the measured size of the contained element in the ranges specified by the `width` and `height` properties.
///
/// There are several constraint types available for each axis. See `ConstrainedSize.Constraint` for a full list and in-depth
/// descriptions of each.
///
/// Notes
/// --------
/// An important note is that the constraints of `ConstrainedSize` are authoritative during measurement. For example,
/// if your `ConstrainedSize` specifies `.atLeast(300)` for `width`, and the `ConstrainedSize` is asked to measure within
/// a `SizeConstraint` that is at most 100 points wide, the returned measurement will still be 300 points. The same goes for the
/// height of the `ConstrainedSize`.
///
public struct ConstrainedSize: Element {

    /// The element whose measurement will be constrained by the `ConstrainedSize`.
    public var wrapped: Element

    /// The constraint to place on the width of the element.
    public var width: Constraint

    /// The constraint to place on the height of the element.
    public var height: Constraint

    /// Creates a new `ConstrainedSize` with the provided constraint options.
    public init(
        width: Constraint = .unconstrained,
        height: Constraint = .unconstrained,
        wrapping element: Element
    ) {
        self.width = width
        self.height = height
        wrapped = element
    }

    public var content: ElementContent {
        ElementContent(
            child: wrapped,
            layout: Layout(width: width, height: height)
        )
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        nil
    }

}

extension ConstrainedSize {

    /// The available ways to constrain the measurement of a given axis within a `ConstrainedSize` element.
    public enum Constraint: Equatable {
        /// There is no constraint for this axis – the natural size of the element will be used.
        case unconstrained

        /// The measured size for this axis will be **no greater** than the value provided.
        case atMost(CGFloat)

        /// The measured size for this axis will be **no less** than the value provided.
        case atLeast(CGFloat)

        /// The measured size for this axis will be **within** the range provided.
        /// If the measured value is below the bottom of the range, the lower value will be used.
        /// If the measured value is above the top of the range, the lower value will be used.
        case within(ClosedRange<CGFloat>)

        /// The measured size for this axis will be **exactly**  the value provided.
        case absolute(CGFloat)

        fileprivate func applied(to value: CGFloat) -> CGFloat {
            switch self {
            case .unconstrained:
                return value
            case let .atMost(max):
                return min(max, value)
            case let .atLeast(min):
                return max(min, value)
            case let .within(range):
                return value.clamped(to: range)
            case let .absolute(absoluteValue):
                return absoluteValue
            }
        }

        func applied(to constraint: SizeConstraint.Axis) -> SizeConstraint.Axis {
            switch constraint {
            case .atMost(let maxValue):
                return .atMost(applied(to: maxValue))
            case .unconstrained:
                switch self {
                case .unconstrained:
                    return .unconstrained
                case let .atMost(max):
                    return .atMost(max)
                case .atLeast:
                    return .unconstrained
                case let .within(range):
                    return .atMost(range.upperBound)
                case let .absolute(absoluteValue):
                    return .atMost(absoluteValue)
                }
            }
        }
    }
}


extension Element {

    /// Constrains the measured size of the element to the provided width and height.
    public func constrainedTo(
        width: ConstrainedSize.Constraint = .unconstrained,
        height: ConstrainedSize.Constraint = .unconstrained
    ) -> ConstrainedSize {
        ConstrainedSize(width: width, height: height, wrapping: self)
    }

    /// Constrains the measured size of the element to the provided width and height.
    public func constrainedTo(
        width: CGFloat,
        height: CGFloat
    ) -> ConstrainedSize {
        ConstrainedSize(
            width: .absolute(width),
            height: .absolute(height),
            wrapping: self
        )
    }

    /// Constrains the measured size of the element to the provided size.
    public func constrainedTo(
        size: CGSize
    ) -> ConstrainedSize {
        ConstrainedSize(
            width: .absolute(size.width),
            height: .absolute(size.height),
            wrapping: self
        )
    }

    /// Constrains the measured size of the element to the provided `SizeConstraint`.
    public func constrained(to sizeConstraint: SizeConstraint) -> ConstrainedSize {
        func toConstrainedSize(_ axis: SizeConstraint.Axis) -> ConstrainedSize.Constraint {
            switch axis {
            case .atMost(let value): return .atMost(value)
            case .unconstrained: return .unconstrained
            }
        }

        return ConstrainedSize(
            width: toConstrainedSize(sizeConstraint.width),
            height: toConstrainedSize(sizeConstraint.height),
            wrapping: self
        )
    }
}


extension Comparable {

    fileprivate func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}


extension ConstrainedSize {

    fileprivate struct Layout: SingleChildLayout {

        var width: Constraint
        var height: Constraint

        func measure(in constraint: SizeConstraint, child: Measurable) -> CGSize {

            // If both height & width are absolute, we can avoid measuring entirely.
            if case let .absolute(width) = width, case let .absolute(height) = height {
                return CGSize(width: width, height: height)
            }

            /// 1) Measure how big the element should be by constraining the passed in
            /// `SizeConstraint` to not be larger than our maximum size. This ensures
            /// the real maximum possible width is passed to the child, not an unconstrained width.
            ///
            /// This is important because some elements heights are affected by their width (eg, a text label),
            /// or any other elements type which reflows its content.

            let maximumConstraint = SizeConstraint(
                width: .init(width.applied(to: constraint.width.maximum)),
                height: .init(height.applied(to: constraint.height.maximum))
            )

            let measurement = child.measure(in: maximumConstraint)

            /// 2) If our returned size needs to be larger than the measured size,
            /// eg: the element did not take up all the space during measurement,
            /// and we have a minimum size in either axis. In that case, adjust the
            /// measured size to that minimum size before returning.

            return CGSize(
                width: width.applied(to: measurement.width),
                height: height.applied(to: measurement.height)
            )
        }

        func layout(size: CGSize, child: Measurable) -> LayoutAttributes {
            LayoutAttributes(size: size)
        }

        func sizeThatFits(
            proposal: SizeConstraint,
            subelement: Subelement,
            environment: Environment,
            cache: inout Cache
        ) -> CGSize {
            if case let .absolute(width) = width, case let .absolute(height) = height {
                return CGSize(width: width, height: height)
            }

            let constrainedProposal = SizeConstraint(
                width: width.applied(to: proposal.width),
                height: height.applied(to: proposal.height)
            )
            let measurement = subelement.sizeThatFits(constrainedProposal)

            return CGSize(
                width: width.applied(to: measurement.width),
                height: height.applied(to: measurement.height)
            )
        }

        func placeSubelement(
            in size: CGSize,
            subelement: Subelement,
            environment: Environment,
            cache: inout ()
        ) {
            subelement.place(filling: size)
        }
    }

}
