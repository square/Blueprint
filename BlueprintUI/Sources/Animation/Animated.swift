//
//  Animated.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 4/6/20.
//

import Foundation



/// A wrapper element which allows controlling if animations from transitions or layouts
/// should occur further down the element tree from this element.
///
/// Note that passing `true` as the animated flag does not mean that animations will always occur;
/// if the element update to a `BlueprintView` is not animated, no animations will occur.
///
/// You can nest `Animated` elements as needed; eg if a subset of an element tree should be animated, and then
/// a subset of the tree from there should not, you would do the following:
///
/// ```
/// Animated(false, wrapping: Column {
///
///    // No animations within MyCustomElement1 will ever occur.
///    $0.add(child: MyCustomElement1())
///
///    // Re-enable animations within this tree.
///    $0.add(child: Animated(true, wrapping: Row {
///
///       // This item will now animate if the BlueprintView's update is animated.
///       $0.add(child: Transition(
///           onAppear: .fadeIn,
///           wrapping: Label(text: "Hello, World!")
///           )
///       )
///
///       // No animations within MyCustomElement2 will ever occur.
///       $0.add(child: Animated(false, wrapping: MyCustomElement2(...)))
///    })
/// })
/// ```
public struct Animated : Element {
    
    /// If animations are enabled or not.
    public var animated : Bool
    
    /// The element wrapped by this animation element.
    public var wrapped : Element
   
    /**
     Should the element animate its child elements.
     */
    public init(_ animated : Bool, wrapping element : Element) {
        
        self.animated = animated
        self.wrapped = element
    }
    
    //
    // MARK: Element
    //
    
    public var content: ElementContent {
        ElementContent(child: self.wrapped)
    }
    
    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        ViewDescription(AnimatedView.self) { config in
            config.builder = { AnimatedView(frame: bounds) }
            config.allowsAnimations = self.animated
        }
    }
    
    /// A view type used when wrapping an `Element` in an `Animated` element.
    final class AnimatedView : UIView {}
}


public extension Element {
    
    func animated(_ animated : Bool) -> Animated {
        Animated(animated, wrapping: self)
    }
}
