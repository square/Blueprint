import Foundation


protocol LayoutValueKey {

    associatedtype Value

    static var defaultValue: Value { get }
}
