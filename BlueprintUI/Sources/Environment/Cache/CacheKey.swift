import Foundation

public protocol CacheKey {
    associatedtype Value
    static var emptyValue: Self.Value { get }
}
