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
}


public extension UIViewElement {
    
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


/// A private type which caches `UIViewElement` views to be reused for sizing and measurement.
private final class UIViewElementMeasurer {
    
    /// The standard shared cache.
    static let shared = UIViewElementMeasurer()
        
    /// Provides the size for the provided element by using a cached measurement view.
    func measure<ViewElement:UIViewElement>(element : ViewElement, in constraint : SizeConstraint) -> CGSize {
        
        let bounds = CGRect(origin: .zero, size: constraint.maximum)
        
        let viewDescription = element.elementViewDescription(bounds: bounds)
        
        let key = Key(
            elementType: ObjectIdentifier(ViewElement.self)
        )
        
        let view : UIView = {
            if let existing = self.views[key] {
                return existing
            } else {
                let new = viewDescription.build()
                self.views[key] = new
                return new
            }
        }()
        
        viewDescription.apply(to: view)
        
        return view.sizeThatFits(bounds.size)
    }
    
    private var views : [Key:UIView] = [:]
    
    private struct Key : Hashable {
        let elementType : ObjectIdentifier
    }
}
