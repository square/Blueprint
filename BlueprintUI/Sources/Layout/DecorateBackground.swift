//
//  DecorateBackground.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 11/4/20.
//

import UIKit


///
/// Places a background behind the given `wrapped` element,
/// and overflows it by the amount specified in `overflow`.
///
/// The size of the element is determined only by the `wrapped` element –
/// that is, the `background` element will overflow the bounds of the element, but not
/// affect its layout or size. This is similar to how UIKit handles shadows: They live outside of the layout
/// rect of the view:
///
/// The arrows represent the measured size of the view for layout purposes.
/// ```
/// ┌───────────────────┐
/// │    Background     │
/// │ ┏━━━━━━━━━━━━━━━┓ │ ▲
/// │ ┃               ┃ │ │
/// │ ┃    Wrapped    ┃ │ │
/// │ ┃               ┃ │ │
/// │ ┗━━━━━━━━━━━━━━━┛ │ ▼
/// └───────────────────┘
///   ◀───────────────▶
/// ```
///
/// This is useful to render on-touch or selected states of elements, where you
/// want to provide a padded background that does otherwise affect the layout of the element,
/// which is likely controlled by its parent element.
///
public struct DecorateBackground : Element {
    
    /// The element which provides the sizing and measurement.
    public var wrapped : Element
    
    /// The element which is used to render the background.
    /// It is stretched to fit the `wrapped` content, plus the `overflow` padding.
    ///
    /// If you have a 100w x 50h element, and an overflow of (10, 10, 10, 10),
    /// the measured sized will be 100w x 50h, and the background will be
    /// sized to be 120w x 70h.
    /// ```
    /// ┌───────────────────┐
    /// │ ┏━━━━━━━━━━━━━━━┓ │ ▲
    /// │ ┃               ┃ │ │
    /// │ ┃    Wrapped    ┃ │ │
    /// │ ┃               ┃ │ │
    /// │ ┗━━━━━━━━━━━━━━━┛ │ ▼
    /// └───────────────────┘
    ///   ◀───────────────▶
    /// ```
    public var background : Element
    
    /// How much the background should overflow the measured bounds of the
    /// element. Positive values overflow outside of the bounds, and negative
    /// values underflow to inside the bounds.
    public var overflow : UIEdgeInsets
    
    /// Creates a new instance with the provided overflow, background, and wrapped element.
    public init(
        overflow: UIEdgeInsets,
        background: () -> Element,
        wrapping: () -> Element
    ) {
        self.wrapped = wrapping()
        self.background = background()
        self.overflow = overflow
    }
    
    /// Creates a new instance with the provided uniform overflow, background, and wrapped element.
    public init(
        uniform: CGFloat,
        background: () -> Element,
        wrapping: () -> Element
    ) {
        self.init(
            overflow: UIEdgeInsets(top: uniform, left: uniform, bottom: uniform, right: uniform),
            background: background,
            wrapping: wrapping
        )
    }
    
    /// Creates a new instance with the provided horizontal and vertical overflow, background, and wrapped element.
    public init(
        horizontal: CGFloat? = nil,
        vertical : CGFloat? = nil,
        background: () -> Element,
        wrapping: () -> Element
    ) {
        self.init(
            overflow: UIEdgeInsets(top: vertical ?? 0, left: horizontal ?? 0, bottom: vertical ?? 0, right: horizontal ?? 0),
            background: background,
            wrapping: wrapping
        )
    }
    
    // MARK: Element
    
    public var content: ElementContent {
        let layout = Layout(overflow: self.overflow)
        
        return ElementContent(layout: layout) { builder in
            builder.add(element: self.background)
            builder.add(element: self.wrapped)
        }
    }
    
    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        nil
    }
}


extension Element {
    
    /// Decorates the element with the provided background for the provided overflow.
    public func decorateBackground(
        with overflow : UIEdgeInsets,
        background : () -> Element
    ) -> Element {
        DecorateBackground(overflow: overflow, background: background, wrapping: { self })
    }
    
    /// Decorates the element with the provided background for the provided uniform overflow.
    public func decorateBackground(
        with uniform : CGFloat,
        background : () -> Element
    ) -> Element {
        DecorateBackground(uniform: uniform, background: background, wrapping: { self })
    }
    
    /// Decorates the element with the provided background for the provided horizontal and vertical overflow.
    public func decorateBackground(
        horizontal: CGFloat? = nil,
        vertical : CGFloat? = nil,
        background : () -> Element
    ) -> Element {
        DecorateBackground(horizontal: horizontal, vertical: vertical, background: background, wrapping: { self })
    }
}


extension DecorateBackground {
    fileprivate struct Layout : BlueprintUI.Layout {
        
        var overflow : UIEdgeInsets
        
        func measure(in constraint: SizeConstraint, items: [(traits: (), content: Measurable)]) -> CGSize {
            
            precondition(items.count == 2)
            
            let wrapped = items[1]
            
            return wrapped.content.measure(in: constraint)
        }
        
        func layout(size: CGSize, items: [(traits: (), content: Measurable)]) -> [LayoutAttributes] {
            
            precondition(items.count == 2)
            
            return [
                LayoutAttributes(frame: CGRect(origin: .zero, size: size).inset(by: self.overflow.inverted)),
                LayoutAttributes(size: size)
            ]
        }
    }
}


extension UIEdgeInsets {
    fileprivate var inverted : UIEdgeInsets {
        UIEdgeInsets(
            top: -self.top,
            left: -self.left,
            bottom: -self.bottom,
            right: -self.right
        )
    }
}
