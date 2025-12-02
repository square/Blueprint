import Foundation

/// Types conforming to this protocol can be used as keys in `HostingViewContext`.
///
/// Using a type as the key allows us to strongly type each value, with the
/// key's `CrossLayoutCacheKey.Value` associated value.
///
/// ## Example
///
/// Usually a key is implemented with an uninhabited type, such an empty enum.
///
///     enum WidgetCountsKey: CrossLayoutCacheKey {
///         static let emptyValue: [WidgetID: Int] = [:]
///     }
///
/// You can write a small extension on `HostingViewContext` to make it easier to use your key.
///
///     extension HostingViewContext {
///         var widgetCounts: [WidgetID: Int] {
///             get { self[WidgetCountsKey.self] }
///             set { self[WidgetCountsKey.self] = newValue }
///         }
///     }
public protocol CrossLayoutCacheKey {
    associatedtype Value
    static var emptyValue: Self.Value { get }
}
