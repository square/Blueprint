import Foundation

// A context in which to evaluate whether or not a value is cacheable.
public enum CrossLayoutCacheableContext: Hashable, Sendable, CaseIterable {

    /// The two values are identicial in every respect that could affect displayed output.
    case all

    // More fine-grained contexts:

    /// The two values are equivalent in all aspects that would affect the size of the element.
    /// - Warning:Non-obvious things may affect element-sizing – for example, setting a time zone may seem like something that would only affect date calculations, but can result in different text being displayed, and therefore affect sizing. Consider carefully whether you are truly affecting sizing or not.
    case elementSizing
}
