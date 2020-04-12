import UIKit

/// Constrains the measured size of the content element.
public struct ConstrainedSize: Element {

    public var wrappedElement: Element

    public var width: Constraint
    public var height: Constraint

    public init(width: Constraint = .unconstrained, height: Constraint = .unconstrained, wrapping element: Element) {
        self.wrappedElement = element
        self.width = width
        self.height = height
    }

    public var content: ElementContent {
        return ElementContent(child: wrappedElement, layout: Layout(width: width, height: height))
    }

    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return nil
    }
}

extension ConstrainedSize {

    public enum Constraint {
        case unconstrained
        case atMost(CGFloat)
        case atLeast(CGFloat)
        case within(ClosedRange<CGFloat>)
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
    }
}

extension Comparable {

    fileprivate func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

extension ConstrainedSize {

    fileprivate struct Layout: SingleChildLayout {
        
        var width: Constraint
        var height: Constraint
        
        func layout(in constraint: SizeConstraint, child: MeasurableChild) -> SingleChildLayoutResult {
            SingleChildLayoutResult(
                size: {
                    var result = child.size(in: constraint)
                    result.width = width.applied(to: result.width)
                    result.height = height.applied(to: result.height)
                    return result
                },
                layoutAttributes: {
                    LayoutAttributes(size: $0)
                }
            )
        }
    }
}


