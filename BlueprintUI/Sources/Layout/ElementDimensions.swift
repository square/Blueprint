import CoreGraphics

/// An element’s size and its alignment guides in its own coordinate space.
///
/// You can access the size of the element through the `width` and `height` properties. You can
/// access alignment guide values by subscripting with the specific alignment.
///
/// These dimensions are typically used when setting an alignment guide on a stack, with
/// `StackElement.add(...)`.
///
/// ## Example
///
/// ```
/// // get the alignment guide value for `VerticalAlignment.center`, falling back to the default
/// // value if no alignment guide has been set
/// dimensions[VerticalAlignment.center]
///
/// // get the alignment guide value for `HorizontalAlignment.trailing`, or `nil` if none has been
/// // set.
/// dimensions[explicit: .trailing]
/// ```
///
/// ## See Also
/// [StackElement.add()](x-source-tag://StackElement.add)
///
public struct ElementDimensions: Equatable {

    /// The element's width
    public internal(set) var width: CGFloat

    /// The element's height
    public internal(set) var height: CGFloat

    private var horizontalGuideValues: [ObjectIdentifier: CGFloat] = [:]
    private var verticalGuideValues: [ObjectIdentifier: CGFloat] = [:]

    init(size: CGSize) {
        width = size.width
        height = size.height
    }

    /// Accesses the value of the given guide, or the default value of the alignment if this
    /// guide has not been set.
    public internal(set) subscript(guide: HorizontalAlignment) -> CGFloat {
        get {
            horizontalGuideValues[ObjectIdentifier(guide.id)] ?? guide.id.defaultValue(in: self)
        }
        set {
            horizontalGuideValues[ObjectIdentifier(guide.id)] = newValue
        }
    }

    /// Accesses the value of the given guide, or the default value of the alignment if this
    /// guide has not been set.
    public internal(set) subscript(guide: VerticalAlignment) -> CGFloat {
        get {
            verticalGuideValues[ObjectIdentifier(guide.id)] ?? guide.id.defaultValue(in: self)
        }
        set {
            verticalGuideValues[ObjectIdentifier(guide.id)] = newValue
        }
    }

    /// Returns the explicit value of the given alignment guide in this view, or
    /// `nil` if no such value exists.
    public subscript(explicit guide: HorizontalAlignment) -> CGFloat? {
        horizontalGuideValues[ObjectIdentifier(guide.id)]
    }

    /// Returns the explicit value of the given alignment guide in this view, or
    /// `nil` if no such value exists.
    public subscript(explicit guide: VerticalAlignment) -> CGFloat? {
        verticalGuideValues[ObjectIdentifier(guide.id)]
    }
}
