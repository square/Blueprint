import BlueprintUI
import UIKit

/// A solid line, parallel to the x or y axis, with a fixed thickness but unconstrained in length,
/// suitable for use as a separator.
public struct Rule: ProxyElement {
    /// Represents whether the rule is parallel to the x or y axis.
    public enum Orientation {
        /// Indicates that the rule is parallel to the x axis.
        case horizontal
        /// Indicates that the rule is parallel to the y axis.
        case vertical
    }

    /// Represents the thickness of a rule in the direction perpendicular to its orientation.
    public enum Thickness {
        /// Indicates that the rule should be exactly 1 screen pixel thick,
        /// the thinnest possible line that can be drawn.
        case hairline
        /// An exact thickness in points.
        case points(CGFloat)

        var value: CGFloat {
            switch self {
            case .hairline:
                return 1.0 / UIScreen.main.scale
            case .points(let points):
                return points
            }
        }
    }

    /// Whether this rule is horizontal or vertical.
    public var orientation: Orientation
    /// The thickness of this rule in the direction perpendicular to its orientation.
    public var thickness: Thickness
    /// The color that the rule should be drawn.
    public var color: UIColor

    /// Initializes a Rule with the given properties.
    ///
    /// - parameters:
    ///   - orientation: Whether the rule is horizontal or vertical.
    ///   - color: The color that the rule should be drawn.
    ///   - thickness: The thickness of the rule in the direction perpendicular to its orientation.
    ///     Defaults to a hairline thickness, meaning the thinnest possible line that can be drawn.
    public init(orientation: Orientation, color: UIColor, thickness: Thickness = .hairline) {
        self.orientation = orientation
        self.color = color
        self.thickness = thickness
    }

    public var elementRepresentation: Element {
        ConstrainedSize(
            width: width,
            height: height,
            wrapping: Box(backgroundColor: color)
        )
    }

    private var width: ConstrainedSize.Constraint {
        switch orientation {
        case .horizontal:
            return .unconstrained
        case .vertical:
            return .absolute(thickness.value)
        }
    }

    private var height: ConstrainedSize.Constraint {
        switch orientation {
        case .horizontal:
            return .absolute(thickness.value)
        case .vertical:
            return .unconstrained
        }
    }
}
