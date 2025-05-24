/// A key for accessing a layout trait value of a layout container's subelements.
///
/// If you create a custom layout by defining a type that conforms to the ``Layout`` protocol, you
/// can also create custom layout traits that you set on individual subelements, and that your
/// container can access to guide its layout behavior. Your custom traits resemble the built-in
/// layout traits such as the grow and shrink priorities of `Row` and `Column`, but have a purpose
/// that you define.
///
/// To create a custom layout trait, first create a type that conforms to this protocol and
/// implement the ``defaultValue`` property.
///
/// ## Set layout traits
///
/// Layout traits are set on subelements as part of the ``ElementContent``. Use the initializer that
/// provides a builder closure, and set layout traits on each subelement by calling the
/// ``ElementContent/Builder/add(traitsType:traits:key:element:)`` method.
///
/// ```swift
/// enum MyPriorityKey: LayoutTraitsKey {
///     static let defaultValue: CGFloat = 0
/// }
///
/// struct MyElement: Element {
///     var children: [(element: Element, priority: CGFloat)]
///
///     var content: ElementContent {
///         ElementContent(layout: MyLayout()) { builder in
///             for (element, priority) in children {
///                 builder.add(
///                     traitsType: MyPriorityKey.self,
///                     traits: priority,
///                     element: element
///                 )
///             }
///         }
///     }
/// }
/// ```
///
/// ## Read layout traits
///
/// To read the layout traits in your layout implementation, use the traits key type as an index on
/// the ``LayoutSubelement``. You can define a convenience property on ``LayoutSubelement`` to make
/// it easier to read the value.
///
/// ```swift
/// extension LayoutSubelement {
///     var myPriority: CGFloat {
///         self[MyPriorityKey.self]
///     }
/// }
///
/// struct MyLayout: Layout {
///     func placeSubelements(
///         in size: CGSize,
///         subelements: Subelements,
///         environment: Environment,
///         cache: inout ()
///     ) {
///         for subelement in subelements {
///             let myPriority = subelement.myPriority
///             // place subelement based on myPriority
///         }
///     }
/// }
/// ```
///
public protocol LayoutTraitsKey {
    /// The type of value stored by this key.
    associatedtype Value

    /// The default value of the trait if it is not set.
    static var defaultValue: Value { get }
}
