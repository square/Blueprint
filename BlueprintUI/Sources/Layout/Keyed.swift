//
//  Keyed.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 4/2/21.
//

import UIKit


///
/// `Keyed` allows providing a `Hashable` value which is used
/// during view updates to uniquely identify content during the diff process
/// between the old and new element structure.
///
/// This is useful if you have two elements of the same type at the same depth
/// in the element hierarchy, and you'd like to differentiate between them, eg
/// for appearance transition purposes.
///
/// Example
/// -------
/// Keying the image returned, so that a transition occurs when changing
/// between a placeholder image and an available photo.
///
/// ```
/// func imageElement() -> Element {
///     if let photo = self.photo {
///         return Image(image: photo)
///                 .transition(.fade)
///                 .keyed("photo")
///     } else {
///         return Image(image: self.placeholder)
///                 .transition(.fade)
///                 .keyed("placeholder")
///     }
/// }
/// ```
public struct Keyed<Wrapped:Element>: Element {
    
    /// The key used to differentiate the element.
    public var key : AnyHashable?
    
    /// The wrapped element.
    public var wrapped : Wrapped
    
    /// Creates a new `Keyed` element with the provided key and wrapped element.
    public init(key: AnyHashable?, wrapping: Wrapped) {
        self.key = key
        self.wrapped = wrapping
    }
    
    public var content: ElementContent {
        ElementContent(
            child: self.wrapped,
            key: self.key,
            layout: KeyedLayout()
        )
    }
    
    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        nil
    }
    
    private struct KeyedLayout: SingleChildLayout {

        func measure(
            child: Measurable,
            in constraint : SizeConstraint,
            with context: LayoutContext
        ) -> CGSize
        {
            child.measure(in: constraint, with: context)
        }
        
        func layout(
            child: Measurable,
            in size : CGSize,
            with context : LayoutContext
        ) -> LayoutAttributes
        {
            LayoutAttributes(size: size)
        }
    }
}


extension Keyed:Equatable where Wrapped:Equatable {}
extension Keyed:AnyComparableElement where Wrapped:Equatable {}
extension Keyed:ComparableElement where Wrapped:Equatable {}


extension Element {
    
    ///
    /// `Keyed` allows providing a `Hashable` value which is used
    /// during view updates to uniquely identify content during the diff process
    /// between the old and new element structure.
    ///
    /// This is useful if you have two elements of the same type at the same depth
    /// in the element hierarchy, and you'd like to differentiate between them, eg
    /// for appearance transition purposes.
    ///
    /// Example
    /// -------
    /// Keying the image returned, so that a transition occurs when changing
    /// between a placeholder image and an available photo.
    ///
    /// ```
    /// func imageElement() -> Element {
    ///     if let photo = self.photo {
    ///         return Image(image: photo)
    ///                 .transition(.fade)
    ///                 .keyed("photo")
    ///     } else {
    ///         return Image(image: self.placeholder)
    ///                 .transition(.fade)
    ///                 .keyed("placeholder")
    ///     }
    /// }
    /// ```
    public func keyed(_ key : AnyHashable) -> Keyed<Self> {
        Keyed(key: key, wrapping: self)
    }
}
