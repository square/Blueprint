import Foundation


public protocol LayoutValueKey {

    associatedtype Value

    static var defaultValue: Value { get }
}


public enum GenericLayoutValueKey<LayoutType: Layout>: LayoutValueKey {

    public static var defaultValue: LayoutType.Traits {
        LayoutType.defaultTraits
    }
}
