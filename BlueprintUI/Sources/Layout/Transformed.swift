import UIKit

/// Changes the transform of the wrapped element.
public struct Transformed<Wrapped:Element>: Element {

    /// The content element whose transform is being affected.
    public var wrapped: Wrapped

    /// The transform of the wrapped element.
    public var transform: CATransform3D

    /// Initializes a `Transformed` with the given content element and 3D transform.
    ///
    /// - parameters:
    ///   - transform: The 3D transform to be applied to the wrapped element.
    ///   - wrapping: The content element to be made transparent.
    public init(
        transform: CATransform3D,
        wrapping wrapped: Wrapped
    ) {
        self.transform = transform
        self.wrapped = wrapped
    }

    /// Initializes a `Transformed` with the given content element and DD transform.
    ///
    /// - parameters:
    ///   - transform: The 2D transform to be applied to the wrapped element.
    ///   - wrapping: The content element to be made transparent.
    public init(
        transform: CGAffineTransform,
        wrapping wrapped: Wrapped
    ) {
        self.transform = CATransform3DMakeAffineTransform(transform)
        self.wrapped = wrapped
    }


    public var content: ElementContent {
        return ElementContent(child: wrapped, layout: Layout(transform: transform))
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        return nil
    }
}


extension Transformed:Equatable where Wrapped:Equatable {}
extension Transformed:AnyEquatableElement where Wrapped:Equatable {}
extension Transformed:EquatableElement where Wrapped:Equatable {}


public extension Element {
    /// Wraps the element in an `Transformed` element with the provided 3D transform.
    ///
    /// - parameters:
    ///   - transform: The 3D transform to be applied.
    ///
    func transformed(_ transform: CATransform3D) -> Transformed<Self> {
        Transformed(
            transform: transform,
            wrapping: self
        )
    }

    /// Wraps the element in an `Transformed` element with the provided 2D transform.
    ///
    /// - parameters:
    ///   - transform: The 2D transform to be applied.
    ///
    func transformed(_ transform: CGAffineTransform) -> Transformed<Self> {
        Transformed(
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
    ) -> Transformed<Self>
    {
        Transformed(
            transform: CATransform3DMakeTranslation(translateX, translateY, translateZ),
            wrapping: self
        )
    }

    /// Wraps the element in an `Transformed` element that rotates the receiver in 2D space.
    ///
    /// - parameters:
    ///   - rotate: The angle measurement to rotate the receiver by.
    ///
    func rotated(by rotationAngle: Measurement<UnitAngle>) -> Transformed<Self> {
        Transformed(
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
    ) -> Transformed<Self>
    {
        Transformed(
            transform: CGAffineTransform(scaleX: scaleX, y: scaleY),
            wrapping: self
        )
    }
}


extension CATransform3D : Equatable {
    public static func == (lhs: CATransform3D, rhs: CATransform3D) -> Bool {
        CATransform3DEqualToTransform(lhs, rhs)
    }
}


extension Transformed {
    
    fileprivate struct Layout: SingleChildLayout {
        
        var transform: CATransform3D

        func measure(
            child: Measurable,
            in constraint : SizeConstraint,
            with context: LayoutContext
        ) -> CGSize
        {
            child.measure(in: constraint, with: context)
        }

        func layout(
            child: Measurable,
            in size : CGSize,
            with context : LayoutContext
        ) -> LayoutAttributes
        {
            var attributes = LayoutAttributes(size: size)
            attributes.transform = transform
            
            return attributes
        }
    }
}
