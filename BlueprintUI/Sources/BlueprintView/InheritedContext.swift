//
//  InheritedContext.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 8/3/22.
//

import Foundation


extension BlueprintView {

    struct InheritedContext {
        var environment: Environment

        var unusedRounding: UnusedRounding

        struct UnusedRounding: Equatable {
            var unusedOrigin: CGPoint
            var unusedCorrection: CGPoint

            static var zero: Self {
                .init(unusedOrigin: .zero, unusedCorrection: .zero)
            }
        }
    }
}


extension UIView {

    /// The ``Environment`` for the ``Element`` that this view represents in a Blueprint element tree,
    /// or if the view is not explicitly managed by Blueprint, the ``Environment`` of
    /// the nearest superview that is managed by Blueprint.
    ///
    /// If no views in the superview hierarchy are managed by Blueprint, this property returns nil.
    var inheritedBlueprintContext: BlueprintView.InheritedContext? {
        if let environment = nativeViewNodeBlueprintInheritedContext {
            return environment
        } else if let superview = self.superview {
            return superview.nativeViewNodeBlueprintInheritedContext
        } else {
            return nil
        }
    }

    /// The ``Environment`` for the ``Element`` that this view represents in a Blueprint element tree.
    ///
    /// If this view is not managed by Blueprint, this property returns nil.
    var nativeViewNodeBlueprintInheritedContext: BlueprintView.InheritedContext? {
        get {
            objc_getAssociatedObject(self, &UIView.inheritedContextKey) as? BlueprintView.InheritedContext ?? nil
        }
        set {
            objc_setAssociatedObject(self, &UIView.inheritedContextKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    private static var inheritedContextKey = NSObject()
}
