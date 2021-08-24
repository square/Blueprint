//
//  MeasurementCachingKey.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 7/2/20.
//

import Foundation


///
/// A key which is used to cache both measurement of elements during a Blueprint layout pass.
/// If you have an element which is expensive to measure, you should consider adding a `measurementCacheKey`
/// to improve layout performance.
///
/// You initialize your instance of `MeasurementCachingKey` with both the type of your element,
/// and the value which represents how to render your element on screen – any values which affect the sizing
/// of your element **must** be included in the `input` key.
///
/// Caching is only done on a per-layout pass. Caches are not reused between layout passes.
///
/// Example
/// -------
/// Below is a simplified version of a `MeasurementCachingKey` in action, in this case for Blueprint's `Label` type.
/// ```
/// struct Label : UIViewElement {
///
///     var text : String
///     var font : UIFont
///     var numberOfLines : Int
///
///     typealias UIViewType = UILabel
///
///     func makeUIView() -> UILabel {
///         UILabel()
///     }
///
///     func updateUIView(_ view : UILabel) {
///         view.text = self.text
///         view.font = self.font
///         view.numberOfLines = self.numberOfLines
///     }
///
///     var measurementCacheKey : AnyHashable? {
///         MeasurementCachingKey(
///             type: Self.self,
///             input: Key(
///               text: self.text,
///               font: self.font,
///               numberOfLines: self.numberOfLines
///             )
///         )
///     }
///
///     struct Key : Hashable {
///         var text : String
///         var font : UIFont
///         var numberOfLines : Int
///     }
/// }
/// ```
/// You may notice that the `Key`'s stored properties are identical to the stored properties of the Label type itself.
/// When this occurs, you can simplify your implementation like this, by making the `Element` conform to `Hashable`.
///
/// ```
/// struct Label : UIViewElement, Hashable {
///
///     var text : String
///     var font : UIFont
///     var numberOfLines : Int
///
///     typealias UIViewType = UILabel
///
///     func makeUIView() -> UILabel {
///         UILabel()
///     }
///
///     func updateUIView(_ view : UILabel) {
///         view.text = self.text
///         view.font = self.font
///         view.numberOfLines = self.numberOfLines
///     }
///
///     var measurementCacheKey : AnyHashable? {
///         MeasurementCachingKey(
///         type: Self.self,
///         input: self
///     }
/// }
/// ```
public struct MeasurementCachingKey: Hashable {
    private let elementType: ObjectIdentifier
    private let input: AnyHashable

    public init<ElementType: Element, Input: Hashable>(type: ElementType.Type, input: Input) {
        elementType = ObjectIdentifier(type)
        self.input = input
    }
}
