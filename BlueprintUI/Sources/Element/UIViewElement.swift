//
//  UIViewElement.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 6/4/20.
//

import UIKit


///
/// An element type  which makes it easier to wrap an existing `UIView` instance that
/// provides its own sizing via `sizeThatFits`. An instance of the view is used for
/// sizing and measurement, so that you do not need to re-implement your own measurement.
///
/// Note
/// ----
/// The sizing and measurement prototype view is kept alive for the lifetime of the containing application.
/// Do not pass anything to the initializer of this type that you expect to be quickly released.
///
/// Example
/// -------
/// If you were implementing a very basic `Switch` element, your implementation would look something
/// like this:
/// ```
/// struct Switch : UIViewElement
/// {
///     var isOn : Bool
///
///     typealias UIViewType = UISwitch
///
///     static func makeUIView() -> UISwitch {
///         UISwitch()
///     }
///
///     func updateUIView(_ view: UISwitch, with context: UIViewElementContext) {
///         view.isOn = self.isOn
///     }
/// }
/// ```
public protocol UIViewElement : Element {
    
    /// The type of the view associated with the element.
    associatedtype UIViewType : UIView
        
    /// Create and return a new instance of the provided view type.
    ///
    /// Note
    /// ----
    /// Ensure that you do not pass any values to the initializer of your view type
    /// that you cannot also update in `updateUIView(_:)`, as view instances
    /// are reused for sizing and measurement.
    static func makeUIView() -> UIViewType

    /// Update the view instance with the content from the element. The context provides additional
    /// information, such as whether the update is for the measuring instance.
    ///
    /// Example
    /// -------
    /// If you were to implement a simple `UIViewElement` which wraps a `UISwitch`,
    /// your update method would look like this:
    /// 
    /// ```
    /// func updateUIView(_ view: UISwitch, with context: UIViewElementContext) {
    ///    view.isOn = self.isOn
    /// }
    /// ```
    func updateUIView(_ view: UIViewType, with context: UIViewElementContext)
    
    /// A key which is used to cache measurement results of the `UIViewElement`.
    /// If your element is made of values which can be easily combined to cache its sizing,
    /// you should return them from this variable, to speed up measurement and layout.
    var measurementCacheKey : AnyHashable? { get }
    
    /// Returns the sizing measurement for the element for the provided
    /// measurement view.
    ///
    /// You usually do not need to implement this method – the default implementation of
    /// this method simply calls `sizeThatFits(_:)` on the provided view.
    ///
    /// The view is fully configured and updated before this method is called – you do not need to
    /// update it in any way.
    ///
    /// When To Override
    /// ----------------
    /// You may want to override this method if you need to mutate the value returned from `sizeThatFits(_:)`,
    /// or if you want to use some other sizing method like `systemLayoutSizeFitting(...)`.
    func size(_ size : CGSize, thatFits view : UIViewType) -> CGSize
}


public extension UIViewElement {
    
    var measurementCacheKey : AnyHashable? {
        nil
    }
    
    /// The default implementation simply forwards to `sizeThatFits(_:)`.
    func size(_ size : CGSize, thatFits view : UIViewType) -> CGSize {
        view.sizeThatFits(size)
    }
    
    //
    // MARK: Element
    //
    
    /// Defer to the reused measurement view to provide the size of the element.
    var content: ElementContent {
        let key = self.measurementCacheKey.map {
            MeasurementCachingKey(type: Self.self, input: $0)
        }
        
        return ElementContent(measurementCachingKey: key) {
            UIViewElementMeasurer.shared.measure(element: self, in: $0)
        }
    }
    
    /// Provide the view for the element.
    func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        UIViewType.describe { config in
            config.builder = {
                Self.makeUIView()
            }
            
            config.apply { view in
                self.updateUIView(view, with: .init(isMeasuring: false))
            }
        }
    }
}

/// Context object passed into `updateUIView`.
public struct UIViewElementContext {
    /// This bool indicates whether the view being updated is the static measuring instance. You may
    /// not want to perform certain updates if it is (such as updating field trigger references).
    public var isMeasuring: Bool
}

/// An private type which caches `UIViewElement` views to be reused for sizing and measurement.
private final class UIViewElementMeasurer {
    
    /// The standard shared cache.
    static let shared = UIViewElementMeasurer()
        
    /// Provides the size for the provided element by using a cached measurement view.
    func measure<ViewElement:UIViewElement>(element : ViewElement, in constraint : SizeConstraint) -> CGSize {
        
        let bounds = CGRect(origin: .zero, size: constraint.maximum)
        
        let view = self.measurementView(for: element)
        
        element.updateUIView(view, with: .init(isMeasuring: true))
        
        return element.size(bounds.size, thatFits: view)
    }
    
    func measurementView<ViewElement:UIViewElement>(for element : ViewElement) -> ViewElement.UIViewType
    {
        let key = Key(
            elementType: ObjectIdentifier(ViewElement.self)
        )
        
        if let existing = self.views[key] {
            return existing as! ViewElement.UIViewType
        } else {
            let new = ViewElement.makeUIView()
            self.views[key] = new
            return new
        }
    }
    
    private var views : [Key:UIView] = [:]
    
    private struct Key : Hashable {
        let elementType : ObjectIdentifier
    }
}

