import UIKit

/// Changes the transform of the wrapped element.
public struct Transformed: Element {

    /// The content element whose transform is being affected.
    public var wrappedElement: Element

    /// The transform of the wrapped element.
    public var transform: CATransform3D

    /// Initializes a `Transformed` with the given content element and 3D transform.
    ///
    /// - parameters:
    ///   - transform: The 3D transform to be applied to the wrapped element.
    ///   - wrapping: The content element to be made transparent.
    public init(
        transform: CATransform3D,
        wrapping wrappedElement: Element
    ) {
        self.transform = transform
        self.wrappedElement = wrappedElement
    }

    /// Initializes a `Transformed` with the given content element and DD transform.
    ///
    /// - parameters:
    ///   - transform: The 2D transform to be applied to the wrapped element.
    ///   - wrapping: The content element to be made transparent.
    public init(
        transform: CGAffineTransform,
        wrapping wrappedElement: Element
    ) {
        self.transform = CATransform3DMakeAffineTransform(transform)
        self.wrappedElement = wrappedElement
    }


    public var content: ElementContent {
        return ElementContent(child: wrappedElement, layout: Layout(transform: transform))
    }

    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return nil
    }

    private struct Layout: SingleChildLayout {
        var transform: CATransform3D

        func measure(in constraint: SizeConstraint, child: Measurable) -> CGSize {
            return child.measure(in: constraint)
        }

        func layout(size: CGSize, child: Measurable) -> LayoutAttributes {
            var attributes = LayoutAttributes(size: size)
            attributes.transform = transform
            return attributes
        }
    }
}

public extension Element {
    /// Wraps the element in an `Transformed` element with the provided 3D transform.
    ///
    /// - parameters:
    ///   - transform: The 3D transform to be applied.
    ///
    func transformed(_ transform: CATransform3D) -> Transformed {
        return Transformed(
            transform: transform,
            wrapping: self
        )
    }

    /// Wraps the element in an `Transformed` element with the provided 2D transform.
    ///
    /// - parameters:
    ///   - transform: The 2D transform to be applied.
    ///
    func transformed(_ transform: CGAffineTransform) -> Transformed {
        return Transformed(
            transform: transform,
            wrapping: self
        )
    }

    /// Wraps the element in an `Transformed` element that translates the receiver in 3D space.
    ///
    /// - parameters:
    ///   - transformX: The X component of the translation.
    ///   - transformY: The Y component of the translation.
    ///   - transformZ: The Z component of the translation.
    ///
    func translated(
        translateX: CGFloat = 0,
        translateY: CGFloat = 0,
        translateZ: CGFloat = 0
    ) -> Transformed {
        return Transformed(
            transform: CATransform3DMakeTranslation(translateX, translateY, translateZ),
            wrapping: self
        )
    }

    /// Wraps the element in an `Transformed` element that rotates the receiver in 2D space.
    ///
    /// - parameters:
    ///   - rotate: The angle measurement to rotate the receiver by.
    ///
    func rotated(by rotationAngle: Measurement<UnitAngle>) -> Transformed {
        return Transformed(
            transform: CGAffineTransform(
                rotationAngle: CGFloat(rotationAngle.converted(to: .radians).value)
            ),
            wrapping: self
        )
    }

    /// Wraps the element in an `Transformed` element that scales the receiver in 2D space.
    ///
    /// - parameters:
    ///   - scaleX: The X axis scale.
    ///   - scaleY: The Y axis scale.
    ///
    func scaled(
        scaleX: CGFloat = 1,
        scaleY: CGFloat = 1
    ) -> Transformed {
        return Transformed(
            transform: CGAffineTransform(scaleX: scaleX, y: scaleY),
            wrapping: self
        )
    }
}
