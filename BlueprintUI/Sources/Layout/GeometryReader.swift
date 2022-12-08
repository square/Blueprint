import UIKit

/// An element that dynamically builds its content based on the available space.
///
/// Use this element to build elements whose contents may change responsively to
/// different layouts.
///
/// ## Example
///
/// ```swift
/// GeometryReader { (geometry) -> Element in
///     let image: UIImage
///     switch geometry.constraint.width.maximum {
///     case ..<100:
///         image = UIImage(named: "small")!
///     case 100..<500:
///         image = UIImage(named: "medium")!
///     default:
///         image = UIImage(named: "large")!
///     }
///     return Image(image: image)
/// }
/// ```
///
public struct GeometryReader: Element {
    /// Return the contents of this element based on the current layout.
    var elementRepresentation: (GeometryProxy) -> Element

    public init(elementRepresentation: @escaping (GeometryProxy) -> Element) {
        self.elementRepresentation = elementRepresentation
    }

    public var content: ElementContent {
        ElementContent { phase, constraint, environment, layoutModeCache -> Element in
            let geometry = GeometryProxy(
                environment: environment,
                constraint: constraint,
                layoutModeCache: layoutModeCache
            )
            return self.elementRepresentation(geometry)
        }
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        nil
    }
}

/// Contains information about the current layout being measured by GeometryReader
public struct GeometryProxy {
    var environment: Environment

    /// The size constraint of the element being laid out.
    public var constraint: SizeConstraint
    
    var layoutModeCache: LayoutModeDependentCache

    /// Measure the given element, constrained to the same size as the `GeometryProxy` itself (unless a constraint is explicitly provided).
    public func measure(
        element: Element,
        key: AnyHashable, //? = nil,
        in explicit: SizeConstraint? = nil
    ) -> CGSize {
//        if let key = key {
            let cache = layoutModeCache.outOfBandCache(for: key)
            return element.content.measure(
                in: explicit ?? constraint,
                environment: environment,
                layoutModeCache: cache
            )
//        } else {
//            return element.content.measure(in: explicit ?? constraint, environment: environment)
//        }
    }
}
