import UIKit

/// Contains layout-related metrics for an element.
public struct LayoutAttributes {

    /// Corresponds to `UIView.center`.
    public var center: CGPoint {
        didSet { validateCenter() }
    }

    /// Corresponds to `UIView.bounds`.
    public var bounds: CGRect {
        didSet { validateBounds() }
    }

    /// Corresponds to `UIView.layer.transform`.
    public var transform: CATransform3D {
        didSet { validateTransform() }
    }

    /// Corresponds to `UIView.alpha`.
    public var alpha: CGFloat {
        didSet { validateAlpha() }
    }

    public init() {
        self.init(center: .zero, bounds: .zero)
    }

    public init(frame: CGRect) {
        self.init(
            center: CGPoint(x: frame.midX, y: frame.midY),
            bounds: CGRect(origin: .zero, size: frame.size)
        )
    }

    public init(size: CGSize) {
        self.init(frame: CGRect(origin: .zero, size: size))
    }

    public init(center: CGPoint, bounds: CGRect) {
        self.center = center
        self.bounds = bounds
        transform = CATransform3DIdentity
        alpha = 1.0

        validateBounds()
        validateCenter()
        validateTransform()
        validateAlpha()
    }

    public var frame: CGRect {
        get {
            var f = CGRect.zero
            f.size = bounds.size
            f.origin.x = center.x - f.size.width / 2.0
            f.origin.y = center.y - f.size.height / 2.0
            return f
        }
        set {
            bounds.size = newValue.size
            center.x = newValue.midX
            center.y = newValue.midY
        }
    }

    internal func apply(to view: UIView) {
        view.bounds = bounds
        view.center = center
        view.layer.transform = transform
        view.alpha = alpha
    }


    // Given nested layout attributes:
    //
    //    ┌───────────────────────────────────────────────┐
    //    │          ┌──────────────────────────────────┐ │
    //    │          │a                                 │ │
    //    │          │                                  │ │
    //    │          │                                  │ │
    //    │          │ ┌───────────────────┐            │ │
    //    │          │ │b                  │            │ │
    //    │          │ │                   │            │ │
    //    │          │ │                   │            │ │
    //    │          │ │                   │            │ │
    //    │          │ │                   │            │ │
    //    │          │ └───────────────────┘            │ │
    //    │          └──────────────────────────────────┘ │
    //    └───────────────────────────────────────────────┘
    //
    //  `let c = b.within(layoutAttributes: a)` results in:
    //
    //    ┌───────────────────────────────────────────────┐
    //    │                                               │
    //    │                                               │
    //    │                                               │
    //    │                                               │
    //    │            ┌───────────────────┐              │
    //    │            │c                  │              │
    //    │            │                   │              │
    //    │            │                   │              │
    //    │            │                   │              │
    //    │            │                   │              │
    //    │            └───────────────────┘              │
    //    │                                               │
    //    └───────────────────────────────────────────────┘
    //
    /// Concatonates layout attributes, moving the receiver from the local
    /// coordinate space of `layoutAttributes` and into its parent coordinate
    /// space.
    ///
    /// - parameter layoutAttributes: Another layout attributes object representing
    ///   a parent coordinate space.
    ///
    /// - returns: The resulting combined layout attributes object.
    public func within(_ layoutAttributes: LayoutAttributes) -> LayoutAttributes {

        var t: CATransform3D = CATransform3DIdentity
        t = CATransform3DTranslate(t, -layoutAttributes.bounds.midX, -layoutAttributes.bounds.midY, 0.0)
        t = CATransform3DConcat(
            t,
            layoutAttributes.transform
        )
        t = CATransform3DConcat(
            t,
            CATransform3DMakeTranslation(layoutAttributes.center.x, layoutAttributes.center.y, 0.0)
        )

        var result = LayoutAttributes(
            center: center.applying(t),
            bounds: bounds
        )

        result.transform = CATransform3DConcat(transform, t.untranslated)
        result.alpha = alpha * layoutAttributes.alpha

        return result
    }

    private func validateBounds() {
        assert(bounds.isFinite, "LayoutAttributes.bounds must only contain finite values.")
    }

    private func validateCenter() {
        assert(center.isFinite, "LayoutAttributes.center must only contain finite values.")
    }

    private func validateTransform() {
        assert(transform.isFinite, "LayoutAttributes.transform only not contain finite values.")
    }

    private func validateAlpha() {
        assert(alpha.isFinite, "LayoutAttributes.alpha must only contain finite values.")
    }

    /// Performs rounding on the frame to snap to pixel boundaries.
    ///
    /// - Parameters:
    ///   - origin: The global origin to offset the frame by before rounding. This offset is used to ensure that
    ///     positive and negative frame coordinates both round away from zero.
    ///   - correction: The amount of rounding correction to apply to the origin before rounding, to account for the
    ///     rounding applied to this node's parent.
    ///   - scale: The screen scale to use when rounding.
    mutating func round(from origin: CGPoint, correction: CGPoint, scale: CGFloat) -> CGPoint {
        // Apply origin offset and rounding correction
        let correctedFrame = frame
            .offset(by: origin)
            .offset(by: correction)

        // Round
        let roundedFrame = correctedFrame
            .rounded(.toNearestOrAwayFromZero, by: scale)

        // Save rounding correction
        let roundingCorrection = correctedFrame.origin - roundedFrame.origin

        // Reverse origin offset and set new frame
        frame = roundedFrame
            .offset(by: -origin)

        return roundingCorrection
    }
}

extension LayoutAttributes: Equatable {

    public static func == (lhs: LayoutAttributes, rhs: LayoutAttributes) -> Bool {
        return lhs.center == rhs.center
            && lhs.bounds == rhs.bounds
            && CATransform3DEqualToTransform(lhs.transform, rhs.transform)
            && lhs.alpha == rhs.alpha
    }

}

extension CGRect {
    var isFinite: Bool {
        return origin.isFinite && size.isFinite
    }
}

extension CGPoint {
    var isFinite: Bool {
        return x.isFinite && y.isFinite
    }
}

extension CGSize {
    var isFinite: Bool {
        return width.isFinite && height.isFinite
    }
}

extension CATransform3D {
    var isFinite: Bool {
        return m11.isFinite
            && m12.isFinite
            && m13.isFinite
            && m14.isFinite

            && m21.isFinite
            && m22.isFinite
            && m23.isFinite
            && m24.isFinite

            && m31.isFinite
            && m32.isFinite
            && m33.isFinite
            && m34.isFinite

            && m41.isFinite
            && m42.isFinite
            && m43.isFinite
            && m44.isFinite
    }
}
