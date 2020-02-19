//
//  TransitionAnimation+Predefined.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 2/18/20.
//

import UIKit


public extension TransitionAnimation {
    
    /// Returns a `VisibilityTransition` that scales in and out.
    static var scale: Self {
        return .with(
            animations: AnimatableViewProperties(transform: .init(scaleX: 0.01, y: 0.01))
        )
    }

    /// Returns a `VisibilityTransition` that fades in and out.
    static var fade: Self {
        return .with(
            animations: AnimatableViewProperties(alpha: 0.0)
        )
    }

    /// Returns a `VisibilityTransition` that simultaneously scales and fades in and out.
    static var scaleAndFade: Self {
        return .with(
            animations: AnimatableViewProperties(
                alpha: 0.0,
                transform: .init(scaleX: 0.01, y: 0.01)
            )
        )
    }
    
    /**
     Returns a `VisibilityTransition` that simultaneously slides content in from
     the given direction after given delay, alongside a simultaneous fade animation.
     
     The animation is a spring animation.
     
     The default options provide a slide animation that drops in from the top over 0.5 seconds.
     
     Provide a negative `distance` to slide in from the top, or a positive `distance` to slide in
     from the bottom.
     */
    static func slideIn(
        from distance : CGFloat = -50.0,
        after delay : TimeInterval = 0.0,
        for duration : TimeInterval = 0.5
    ) -> Self {
        
        return TransitionAnimation.with(
            options: AnimationOptions(
                animationKind: .spring(dampingRatio: 0.5, velocity: 0.3),
                delay: delay,
                duration: duration,
                curve: .easeOut
            ),
            animations: AnimatableViewProperties(
                alpha: 0.0,
                transform: CGAffineTransform(translationX: 0.0, y: distance)
            )
        )
    }
}
