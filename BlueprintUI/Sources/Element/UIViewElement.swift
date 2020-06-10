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
/// If you were implementing a very basic `Image` element, your implementation would look something
/// like this:
/// ```
/// struct Image : UIViewElement {
///
///     var image : UIImage
///
///     typealias UIViewType = UIImageView
///
///     static func makeUIView() -> UIImageView {
///         UIImageView()
///     }
///
///     func updateUIView(_ view: UIImageView) {
///         view.image = self.image
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

    /// Update the view instance with the content from the element.
    ///
    /// Example
    /// -------
    /// If you were to implement a simple `UIViewElement` which wraps a `UIImageView`,
    /// your update method would look like this:
    /// 
    /// ```
    /// func updateUIView(_ view: UIImageView) {
    ///    view.image = self.image
    /// }
    /// ```
    func updateUIView(_ view: UIViewType)
    
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
    
    /// The default implementation simply forwards to `sizeThatFits(_:)`.
    func size(_ size : CGSize, thatFits view : UIViewType) -> CGSize {
        view.sizeThatFits(size)
    }
    
    //
    // MARK: Element
    //
    
    /// Defer to the reused measurement view to provide the size of the element.
    var content: ElementContent {
        ElementContent {
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
                self.updateUIView(view)
            }
        }
    }
}


/// An private type which caches `UIViewElement` views to be reused for sizing and measurement.
private final class UIViewElementMeasurer {
    
    /// The standard shared cache.
    static let shared = UIViewElementMeasurer()
        
    /// Provides the size for the provided element by using a cached measurement view.
    func measure<ViewElement:UIViewElement>(element : ViewElement, in constraint : SizeConstraint) -> CGSize {
        
        let bounds = CGRect(origin: .zero, size: constraint.maximum)
        
        let view = self.measurementView(for: element)
        
        element.updateUIView(view)
        
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
