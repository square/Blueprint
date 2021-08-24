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
public struct Keyed: Element {

    /// The key used to differentiate the element.
    public var key: AnyHashable?

    /// The wrapped element.
    public var wrapped: Element

    /// Creates a new `Keyed` element with the provided key and wrapped element.
    public init(key: AnyHashable?, wrapping: Element) {
        self.key = key
        wrapped = wrapping
    }

    public var content: ElementContent {
        ElementContent(
            child: wrapped,
            key: key,
            layout: KeyedLayout()
        )
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        nil
    }

    private struct KeyedLayout: SingleChildLayout {
        func measure(in constraint: SizeConstraint, child: Measurable) -> CGSize {
            child.measure(in: constraint)
        }

        func layout(size: CGSize, child: Measurable) -> LayoutAttributes {
            LayoutAttributes(size: size)
        }
    }
}


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
    public func keyed(_ key: AnyHashable) -> Keyed {
        Keyed(key: key, wrapping: self)
    }
}
