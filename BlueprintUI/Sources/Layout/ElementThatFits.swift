import UIKit

/// An element that adapts to the available space by providing the first child view that fits.
///
/// `ElementThatFits` evaluates its child views in the order you provide them to the initializer.
/// It selects the first child whose ideal size on the constrained axes fits within the proposed size.
/// This means that you provide views in order of preference. Usually this order is largest to smallest,
/// but since an element might fit along one constrained axis but not the other, this isn’t always the case.
/// By default, `ElementThatFits` constrains in both the horizontal and vertical axes.
///
public struct ElementThatFits: ProxyElement {

    public var axes: Set<Axis>
    public var elements: [Element]

    /// Produces an element constrained in the given axes from one of several alternatives provided by a builder.
    public init(
        in axes: Set<Axis> = [.horizontal, .vertical],
        @Builder<Element> elements: () -> [Element]
    ) {
        self.axes = axes
        self.elements = elements()
    }

    public var elementRepresentation: any Element {
        GeometryReader { proxy in

            guard axes.isEmpty == false else {
                /// We have no constraints, just return the first element.
                return elements.first ?? Empty()
            }

            let fitting = proxy.constraint.fittingConstraint(for: axes)
            let measurement = proxy.constraint.measurementConstraint(for: axes)

            for element in elements {
                let measurement = proxy.measure(element: element, in: measurement)

                if axes.contains(.horizontal), let max = fitting.width.constrainedValue {
                    if max < measurement.width {
                        continue
                    }
                }

                if axes.contains(.vertical), let max = fitting.height.constrainedValue {
                    if max < measurement.width {
                        continue
                    }
                }

                return element
            }

            // Nothing passed, let's just go with the last element, which should be smallest.

            return elements.last ?? Empty()
        }
    }
}


extension ElementThatFits {

    /// The axes to use when measuring an element within an `ElementThatFits`.
    public enum Axis {

        /// The horizontal dimension will be returned, with the height being unconstrained.
        case horizontal

        /// The vertical dimension will be returned, with the width being unconstrained.
        case vertical
    }
}

extension SizeConstraint {

    fileprivate func measurementConstraint(for constraints: Set<ElementThatFits.Axis>) -> SizeConstraint {
        .init(
            width: constraints.contains(.horizontal) ? .unconstrained : width,
            height: constraints.contains(.vertical) ? .unconstrained : height
        )
    }

    fileprivate func fittingConstraint(for constraints: Set<ElementThatFits.Axis>) -> SizeConstraint {
        .init(
            width: constraints.contains(.horizontal) ? width : .unconstrained,
            height: constraints.contains(.vertical) ? height : .unconstrained
        )
    }
}
