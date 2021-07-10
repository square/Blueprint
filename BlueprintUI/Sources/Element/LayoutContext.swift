//
//  LayoutContext.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 7/2/21.
//

import UIKit


///
/// The ``LayoutContext`` is an object that is passed through the element hierarchy during
/// layout and measurement passes, to give easy access to the ``Environment``, measurement
/// views, etc.
///
/// You usually do not create a ``LayoutContext`` yourself outside of testing contexts. Instead,
/// utilize the ``LayoutContext`` passed to your ``ElementContent`` to correctly measure
/// your content in the right environment and context:
/// ```
/// var content : ElementContent {
///     ElementContent { size, context -> CGSize in
///         self.wrapped.content.measure(in: size, with: context)
///     }
/// }
/// ```
public struct LayoutContext {
    
    // MARK: Environment

    /// The current `Environment` for the `Element`.
    public var environment : Environment
    
    // MARK: Making New Contexts
        
    /// Creates a new root context to pass to a root `Element` when you would like to measure
    /// that element.
    ///
    /// You usually don't need to call this method yourself outside of tests. Instead,
    /// pass through the `LayoutContext` that your `ElementContent` or `Layout` itself
    /// was passed as part of the measurement and layout cycle.
    public static func rootContext(with environment : Environment = .empty) -> Self {
        Self(
            environment: environment,
            measurementCache: .init(),
            measurementViews: .init()
        )
    }
    
    // MARK: Measuring Content
    
    /// Allows measuring of a prototype view in order to determine the size of an element during a
    /// measurement and layout pass.
    ///
    /// Pass the method the containing element, as well as the view to use for measurement.
    /// The method will pass back a cached prototype view that is retained for the length of the containing
    /// BlueprintView, or if measuring an element outside of a BlueprintView, for the length of the measurement cycle.
    ///
    /// The view passed to the method is wrapped in an `@autoclosure`; it will only be created once
    /// per element for the lifetime of the containing Blueprint view or measurement cycle.
    ///
    /// ```
    /// ElementContent { constraint, context -> CGSize in
    ///     context.measure(self, using: MyView()) { view in
    ///         view.configure(with: self)
    ///         return view.sizeThatFits(constraint.maximum)
    ///     }
    /// }
    /// ```
    ///
    /// #### Note
    /// The view passed to this method will be reused for other elements of the same type
    /// throughout the measurement cycle. Do **not** retain a reference to the view outside
    /// of the `measure` closure.
    ///
    public func measure<ElementType:Element, ViewType:UIView>(
        _ element : ElementType,
        using view: @autoclosure () -> ViewType,
        measure : (ViewType) -> CGSize
    ) -> CGSize
    {
        let view = self.measurementViews.view(for: ElementType.self, make: view)
        
        return measure(view)
    }
    
    // MARK: Mutating The Context
    
    /// Returns a new instance of the context by setting the provided key path to the provided value.
    func setting<Value>(
        _ keyPath : WritableKeyPath<Self, Value>,
        to value : Value
    ) -> Self
    {
        var copy = self
        copy[keyPath: keyPath] = value
        return copy
    }
    
    // MARK: Internal
    
    let measurementCache : MeasurementCache
    let measurementViews : MeasurementViews
}


extension LayoutContext {
    
    /// Internal cache used to retain prototype views for measurement operations.
    final class MeasurementViews {
        
        /// Returns a new to use for measurement.
        fileprivate func view<ElementType:Element, ViewType:UIView>(
            for element : ElementType.Type,
            make : () -> ViewType
        ) -> ViewType
        {
            let key = Key(
                viewType: ObjectIdentifier(ViewType.self),
                elementType: ObjectIdentifier(ElementType.self)
            )
            
            if let existing = self.views[key] {
                return existing as! ViewType
            } else {
                let new = make()
                self.views[key] = new
                return new
            }
        }
        
        private var views : [Key:UIView] = [:]
        
        private struct Key : Hashable {
            let viewType : ObjectIdentifier
            let elementType : ObjectIdentifier
        }
    }
}
