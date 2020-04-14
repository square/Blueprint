import BlueprintUI
import UIKit


public struct Pointer: Element {

    public var wrappedElement: Element

    public var style: Style

    public init(style: Style, wrapping element: Element) {
        self.style = style
        self.wrappedElement = element
    }

    public var content: ElementContent {
        return ElementContent(child: wrappedElement)
    }

    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        if #available(iOS 13.4, *) {
            return PointerView.describe { config in
                config[\.style] = style
            }
        } else {
            return nil
        }
    }

}


extension Pointer {

    public enum Style {

        case effect(Effect, Shape? = nil)
        case shape(Shape, constrainedAxes: Axis = [])

    }

    public enum Effect {

        case automatic

        case highlight

        case lift

        case hover(tintMode: TintMode = .overlay, prefersShadow: Bool = false, prefersScaledContent: Bool = true)

    }

}

extension Pointer.Effect {

    public enum TintMode {
        case none
        case overlay
        case underlay
    }

}

extension Pointer {

    public enum Shape {

        case path(UIBezierPath)

        case roundedRect(CGRect, radius: CGFloat = Shape.defaultCornerRadius)

        case verticalBeam(length: CGFloat)

        case horizontalBeam(length: CGFloat)


        public static var defaultCornerRadius: CGFloat {
            if #available(iOS 13.4, *) {
                return UIPointerShape.defaultCornerRadius
            } else {
                return 0
            }
        }
    }

    public struct Axis: OptionSet {

        public var rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        public static let horizontal: Axis = Axis(rawValue: 1 << 0)

        public static let vertical: Axis = Axis(rawValue: 1 << 1)

        public static let both: Axis = [.horizontal, .vertical]

    }

}

@available(iOS 13.4, *)
fileprivate final class PointerView: UIView, UIPointerInteractionDelegate {

    var style: Pointer.Style = .effect(.automatic)

    override init(frame: CGRect) {
        super.init(frame: frame)

        isUserInteractionEnabled = true

        let interaction = UIPointerInteraction(delegate: self)
        addInteraction(interaction)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func pointerInteraction(_ interaction: UIPointerInteraction, styleFor region: UIPointerRegion) -> UIPointerStyle? {
        guard let view = interaction.view else { return nil }
        let targetedPreview = UITargetedPreview(view: view)
        return style.style(with: targetedPreview)
    }

}

extension Pointer.Style {

    @available(iOS 13.4, *)
    fileprivate func style(with preview: UITargetedPreview) -> UIPointerStyle {
        switch self {
        case .effect(let effect, let shape):
            return UIPointerStyle(effect: effect.effect(with: preview), shape: shape?.shape)
        case .shape(let shape, let constrainedAxes):
            return UIPointerStyle(shape: shape.shape, constrainedAxes: constrainedAxes.axis)
        }
    }

}

extension Pointer.Effect {

    @available(iOS 13.4, *)
    fileprivate func effect(with preview: UITargetedPreview) -> UIPointerEffect {
        switch self {
        case .automatic:
            return .automatic(preview)
        case .highlight:
            return .highlight(preview)
        case .lift:
            return .lift(preview)
        case .hover(tintMode: let tintMode, prefersShadow: let prefersShadow, prefersScaledContent: let prefersScaledContent):
            return .hover(
                preview,
                preferredTintMode: tintMode.tintMode,
                prefersShadow: prefersShadow,
                prefersScaledContent: prefersScaledContent
            )
        }
    }

}

extension Pointer.Effect.TintMode {

    @available(iOS 13.4, *)
    fileprivate var tintMode: UIPointerEffect.TintMode {
        switch self {
        case .none:
            return .none
        case .overlay:
            return .overlay
        case .underlay:
            return .underlay
        }
    }

}


extension Pointer.Shape {

    @available(iOS 13.4, *)
    fileprivate var shape: UIPointerShape {
        switch self {
        case .path(let path):
            return .path(path)
        case .roundedRect(let rect, radius: let radius):
            return .roundedRect(rect, radius: radius)
        case .verticalBeam(length: let length):
            return .verticalBeam(length: length)
        case .horizontalBeam(length: let length):
            return .horizontalBeam(length: length)
        }
    }

}


extension Pointer.Axis {

    @available(iOS 13.4, *)
    fileprivate var axis: UIAxis {
        var axis: UIAxis = []
        if contains(.horizontal) {
            axis.insert(.horizontal)
        }
        if contains(.vertical) {
            axis.insert(.vertical)
        }
        return axis
    }

}
