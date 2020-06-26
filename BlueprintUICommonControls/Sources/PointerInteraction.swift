//
//  PointerInteraction.swift
//  BlueprintUICommonControls
//
//  Created by Kyle Van Essen on 6/26/20.
//

import UIKit
import BlueprintUI



/// An `Element` which lets you add `UIPointerInteraction` interactions
/// to the contained `Element`.
///
/// A `UIPointerInteraction` allows you to respond to hover events for buttons,
/// text, icons, etc, when a user is using an iPad that has support for a pointer, usually from a trackpad.
///
/// **Note** – On iOS versions before 13.4, this has no effect.
///
public struct PointerInteraction : Element
{
    /// The element to which the pointer action will be applied.
    public var wrapping : Element
    
    /// How to provide the style based on the coordinate space and pressed keys.
    public typealias StyleProvider = (UICoordinateSpace, UIKeyModifierFlags) -> Style
    
    /// How to provide the style based on the coordinate space and pressed keys.
    public var style : StyleProvider
    
    /// Creates a new `PointerInteraction` instance that wraps the provided element,
    /// styling the interaction via the `StyleProvider`.
    ///
    /// You don't need to provide a `StyleProvider` – the default one will simply
    /// return a `.automatic` style.
    ///
    /// **Note** – On iOS versions before 13.4, this has no effect.
    public init(
        _ wrapping : Element,
        with style : @escaping StyleProvider = { _, _ in .automatic }
    ) {
        self.wrapping = wrapping
        self.style = style
    }
    
    // MARK: Element
    
    public var content: ElementContent {
        .init(child: self.wrapping)
    }
    
    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        
        if #available(iOS 13.4, *) {
            return View.describe { config in
                config.builder = {
                    View(frame: bounds, style: self.style)
                }
                
                config[\.style] = self.style
            }
        } else {
            return nil
        }
    }
}


public extension Element {
    
    /// Creates a new `PointerInteraction` instance that wraps the element,
    /// styling the interaction via the `StyleProvider`.
    ///
    /// You don't need to provide a `StyleProvider` – the default one will simply
    /// return a `.automatic` style.
    ///
    /// **Note** – On iOS versions before 13.4, this has no effect.
    ///
    func pointerInteraction(
        with style : @escaping PointerInteraction.StyleProvider = { _, _ in .automatic }
    ) -> Element {
        PointerInteraction(self, with: style)
    }
}


extension PointerInteraction {
    
    public enum Style {
        
        case effect(Effect, Shape? = nil)
        case shape(Shape, Axis = [])
        case hidden
        
        public static var automatic : Style {
            .effect(.automatic, nil)
        }
        
        @available(iOS 13.4, *)
        func toSystem(with view : UIView) -> UIPointerStyle {
            switch self {
            case .effect(let effect, let shape):
                return UIPointerStyle(effect: effect.toSystem(with: view), shape: shape?.toSystem)
            case .shape(let shape, let axis):
                return UIPointerStyle(shape: shape.toSystem, constrainedAxes: axis.toSystem)
            case .hidden:
                return .hidden()
            }
        }
    }
    
    
    /// An effect that alters a view's appearance when a pointer enters the current region.
    public enum Effect {
        
        /// An automatic styling is used, determined by the system from the
        /// appearance of the content.
        case automatic

        /// A highlight effect is used.
        case highlight

        /// A lifting effect is used.
        case lift

        /// A hover effect is used.
        case hover(
                preferredTintMode: TintMode = .overlay,
                prefersShadow: Bool = false,
                prefersScaledContent: Bool = true
             )
        
        /// An effect that defines how to apply a tint to a view during a pointer interaction.
        public enum TintMode : Equatable {

            case none
            case overlay
            case underlay
            
            @available(iOS 13.4, *)
            var toSystem : UIPointerEffect.TintMode {
                switch self {
                case .none: return .none
                case .overlay: return .overlay
                case .underlay: return .underlay
                }
            }
        }
        
        @available(iOS 13.4, *)
        func toSystem(with view : UIView) -> UIPointerEffect {
            switch self {
            case .automatic:
                return .automatic(UITargetedPreview(view: view))
                
            case .highlight:
                return .highlight(UITargetedPreview(view: view))
                
            case .lift:
                return .lift(UITargetedPreview(view: view))
                
            case .hover(let preferredTintMode, let prefersShadow, let prefersScaledContent):
                return .hover(
                    UITargetedPreview(view: view),
                    preferredTintMode: preferredTintMode.toSystem,
                    prefersShadow: prefersShadow,
                    prefersScaledContent: prefersScaledContent
                )
            }
        }
    }
    
    
    /// An object that defines the shape of custom pointers.
    public enum Shape {

        /// The pointer morphs into the given Bézier path.
        case path(UIBezierPath)

        /// The pointer morphs into a rounded rectangle using the provided corner radius.
        case roundedRect(CGRect, radius: CGFloat = Shape.defaultCornerRadius)

        /// The pointer morphs into a vertical beam using the specified length.
        case verticalBeam(length: CGFloat)

        /// The pointer morphs into a horizontal beam using the specified length.
        case horizontalBeam(length: CGFloat)

        /// The default corner radius for a pointer using a rounded rectangle.
        public static var defaultCornerRadius: CGFloat {
            if #available(iOS 13.4, *) {
                return UIPointerShape.defaultCornerRadius
            } else {
                return 0.0
            }
        }
        
        @available(iOS 13.4, *)
        var toSystem : UIPointerShape {
            switch self {
            case .path(let path):
                return .path(path)
            case .roundedRect(let rect, let radius):
                return .roundedRect(rect, radius: radius)
            case .verticalBeam(let length):
                return .verticalBeam(length: length)
            case .horizontalBeam(let length):
                return .horizontalBeam(length: length)
            }
        }
    }
    
    /// Defines a structure that specifies the layout axes.
    public struct Axis : OptionSet {
        
        public static let horizontal : Axis = Axis(rawValue: 0 << 1)
        public static let vertical : Axis = Axis(rawValue: 0 << 2)
        
        public static let both : Axis = [.horizontal, .vertical]
        
        public let rawValue: Int
        
        public init(rawValue : Int) {
            self.rawValue = rawValue
        }
        
        @available(iOS 13.4, *)
        var toSystem : UIAxis {
            var axis = UIAxis()
            
            if self.contains(.horizontal) {
                axis.formUnion(.horizontal)
            }
            
            if self.contains(.vertical) {
                axis.formUnion(.vertical)
            }
            
            return axis
        }
    }
}


extension PointerInteraction {
    
    /// The UIView which wraps the inner element, and is used to add the required
    /// `UIPointerInteraction` to the element.
    fileprivate final class View : UIView, UIPointerInteractionDelegate {
        
        var style : (UICoordinateSpace, UIKeyModifierFlags) -> Style {
            didSet {
                // TODO: How do I trigger updating the interaction type?
                
                self.setNeedsDisplay()
                self.setNeedsLayout()
            }
        }
        
        init(frame : CGRect, style : @escaping StyleProvider) {
            self.style = style
            
            super.init(frame: frame)
            
            if #available(iOS 13.4, *) {
                self.addInteraction(UIPointerInteraction(delegate: self))
            }
        }
        
        @available(*, unavailable) required init?(coder: NSCoder) { fatalError() }
        
        // MARK: UIPointerInteractionDelegate
        
        private var keyModifiers : UIKeyModifierFlags = []
        
        @available(iOS 13.4, *)
        func pointerInteraction(
            _ interaction: UIPointerInteraction,
            regionFor request: UIPointerRegionRequest,
            defaultRegion: UIPointerRegion
        ) -> UIPointerRegion? {
            
            self.keyModifiers = request.modifiers
            
            return defaultRegion
        }

        @available(iOS 13.4, *)
        func pointerInteraction(
            _ interaction: UIPointerInteraction,
            styleFor region: UIPointerRegion
        ) -> UIPointerStyle? {
            
            guard let view = interaction.view else {
                return nil
            }
            
            return self.style(view.coordinateSpace, self.keyModifiers).toSystem(with: view)
        }
    }
}

