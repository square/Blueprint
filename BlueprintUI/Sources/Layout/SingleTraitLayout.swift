/// A protocol for layouts that have a single associated trait type.
///
/// Legacy layout implementations can implement this protocol to easily apply and read their traits
/// without defining a custom trait key type.
public protocol SingleTraitLayout {
    associatedtype Traits

    /// Returns a default traits object.
    static var defaultTraits: Self.Traits { get }
}

enum SingleTraitLayoutTraitsKey<LayoutType: SingleTraitLayout>: LayoutTraitsKey {
    typealias Value = LayoutType.Traits

    static var defaultValue: Value {
        LayoutType.defaultTraits
    }
}
