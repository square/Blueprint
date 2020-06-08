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
/// Example
/// -------
/// If you were implementing a very basic `Label` element, your implementation would look something
/// like this:
/// ```
/// struct Label : UIViewElement {
///
///     var text : String
///     var font : UIFont
///
///     typealias UIViewType = UILabel
///
///     static func makeUIView() -> UILabel {
///         UILabel()
///     }
///
///     func updateUIView(_ view: UILabel) {
///         view.text = self.text
///         view.font = self.font
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
    /// If you were to implement a simple `UIViewElement` which wraps a `UILabel`,
    /// your update method would look like this:
    /// 
    /// ```
    /// func updateUIView(_ view: UILabel) {
    ///     view.text = self.text
    ///     view.font = self.font
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
    /// for example to round it up to an integral pixel value in the case of a `UILabel`, or if you
    /// want to use some other sizing method like `systemLayoutSizeFitting(...)`.
    func size(_ size : CGSize, thatFits view : UIViewType) -> CGSize
}


public extension UIViewElement {
    
    func size(_ size : CGSize, thatFits view : UIViewType) -> CGSize
    {
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
        self.elementViewDescription(bounds: bounds)
    }
}


extension UIViewElement {
    /// Map the create and update methods of `UIViewElement` to a `ViewDescription`.
    func elementViewDescription(bounds: CGRect) -> ViewDescription {
        
        UIViewType.describe {
            $0.builder = {
                Self.makeUIView()
            }
            
            $0.apply {
                self.updateUIView($0)
            }
        }
    }
}


/// An internal type which caches `UIViewElement` views to be reused for sizing and measurement.
final class UIViewElementMeasurer {
    
    /// The standard shared cache.
    static let shared = UIViewElementMeasurer()
        
    /// Provides the size for the provided element by using a cached measurement view.
    func measure<ViewElement:UIViewElement>(element : ViewElement, in constraint : SizeConstraint) -> CGSize {
        
        let bounds = CGRect(origin: .zero, size: constraint.maximum)
        let viewDescription = element.elementViewDescription(bounds: bounds)
        
        let view = self.measurementView(
            for: element,
            viewDescription: viewDescription
        )
        
        viewDescription.apply(to: view)
        
        return element.size(bounds.size, thatFits: view)
    }
    
    func measurementView<ViewElement:UIViewElement>(for element : ViewElement, viewDescription: ViewDescription) -> ViewElement.UIViewType
    {
        let key = Key(
            elementType: ObjectIdentifier(ViewElement.self)
        )
        
        if let existing = self.views[key] {
            return existing as! ViewElement.UIViewType
        } else {
            let new = viewDescription.build()
            self.views[key] = new
            return new as! ViewElement.UIViewType
        }
    }
    
    private var views : [Key:UIView] = [:]
    
    private struct Key : Hashable {
        let elementType : ObjectIdentifier
    }
}
