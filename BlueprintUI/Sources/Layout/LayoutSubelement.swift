import CoreGraphics
import Foundation
import QuartzCore
import UIKit

/// A collection of proxy values that represent the child elements of a layout.
public typealias LayoutSubelements = [LayoutSubelement]

/// A proxy that represents one child element of a layout.
///
/// This type acts as a proxy for a child element in a ``Layout``. Layout protocol methods receive a
/// ``LayoutSubelements`` collection that contains exactly one proxy for each of the child elements
/// managed by the layout.
///
/// Use this proxy to get information about the associated element, like its size and traits. You
/// should also use the proxy to tell its corresponding element where to appear by calling the
/// proxy’s ``place(at:anchor:size:)`` method. Do this once for each subview from your
/// implementation of the layout’s
/// ``CaffeinatedLayout/placeSubelements(in:subelements:environment:cache:)`` method.
///
/// - Note: The ``LayoutSubelement`` API, and its documentation, are modeled after SwiftUI's
///   [LayoutSubview](https://developer.apple.com/documentation/swiftui/layoutsubview), with major
///   differences noted.
///
public struct LayoutSubelement {

    typealias SizeCache = HintingSizeCache

    var identifier: ElementIdentifier
    private var content: ElementContent
    var environment: Environment
    var node: LayoutTreeNode
    private var traits: Any

    private var cache: HintingSizeCache { node.sizeCache }

    @Storage
    private(set) var placement: Placement?

    /// Optional attributes to apply to this subelement, such as opacity and transforms.
    @Storage
    public var attributes = Attributes()

    init(
        identifier: ElementIdentifier,
        content: ElementContent,
        environment: Environment,
        node: LayoutTreeNode,
        traits: Any
    ) {
        self.identifier = identifier
        self.content = content
        self.environment = environment
        self.node = node
        self.traits = traits
    }

    /// Assigns a position and size to a subelement.
    ///
    /// Call this method from your implementation of the `Layout` protocol’s
    /// ``CaffeinatedLayout/placeSubelements(in:subelements:environment:cache:)`` method for each
    /// subelement arranged by the layout. Provide a position within the container’s bounds where
    /// the subelement should appear, an anchor that indicates which part of the subelement appears
    /// at that point, and a size.
    ///
    /// To learn the subelement's preferred size for a given proposal before calling this method,
    /// you can call ``sizeThatFits(_:)`` method on the subelement.
    ///
    /// If you call this method more than once for a subelement, the last call takes precedence. If
    /// you don’t call this method for a subelement, the subelement fills the bounds of its
    /// container.
    ///
    /// - Parameters:
    ///   - position: The place where the anchor of the subelement should appear in its container,
    ///     relative to the container's bounds.
    ///   - anchor: The unit point on the subelement that appears at `position`. You can use a
    ///     built-in point, like ``UnitPoint/center``, or you can create a custom ``UnitPoint``.
    ///   - size: The size of the subelement. In Blueprint, parents choose their children's size.
    ///     You can determine a good size for a subelement by calling ``sizeThatFits(_:)`` on it.
    public func place(
        at position: CGPoint,
        anchor: UnitPoint = .topLeading,
        size: CGSize
    ) {
        placement = Placement(position: position, anchor: anchor, size: size)
    }

    /// Assigns a position and size to a subelement.
    ///
    /// This is a convenience for calling ``place(at:anchor:size:)`` with `frame.origin` and
    /// `frame.size`.
    ///
    /// - Parameters:
    ///   - frame: The position and size of the subelement. The origin of this frame represents the
    ///     place where the anchor of the subelement should appear in its container, relative to the
    ///     container's bounds. In Blueprint, parents choose their children's size. You can
    ///     determine a good size for a subelement by calling ``sizeThatFits(_:)`` on it.
    ///   - anchor: The unit point on the subelement that appears at `position`. You can use a
    ///     built-in point, like ``UnitPoint/center``, or you can create a custom ``UnitPoint``.
    public func place(
        in frame: CGRect,
        anchor: UnitPoint = .topLeading
    ) {
        place(at: frame.origin, anchor: anchor, size: frame.size)
    }

    /// Assigns a position and size to a subelement.
    ///
    /// This is a convenience for calling ``place(at:anchor:size:)`` with a position of `.zero` and
    /// this size.
    public func place(
        filling size: CGSize
    ) {
        place(at: .zero, size: size)
    }

    /// Asks the subelement for its size.
    ///
    /// In Blueprint, elements are ultimately sized by their parents, but you can use this method to
    /// determine the size that a subelement would prefer.
    ///
    /// - Parameter proposal: A proposed size constraint for the subelement.
    /// - Returns: The size that the subelement would choose for itself, given the proposal.
    public func sizeThatFits(_ proposal: SizeConstraint) -> CGSize {
        cache.get(key: proposal) { proposal in
            content.sizeThatFits(proposal: proposal, environment: environment, node: node)
        }
    }

    /// Gets the layout traits of the subelement.
    ///
    /// Use this method to access the layout-specific ``LegacyLayout/Traits`` value for this
    /// subelement.
    ///
    /// - Important: Only call this method with the type of your `Layout`. For compatibility with
    ///   legacy layout, this is the only type of traits supported.
    ///
    /// - Parameter layoutType: The type of layout, which determines the type of the traits.
    /// - Returns: The subelements's layout traits.
    public func traits<LayoutType>(
        forLayoutType layoutType: LayoutType.Type
    ) -> LayoutType.Traits where LayoutType: Layout {
        traits as! LayoutType.Traits
    }
}

extension LayoutSubelement {
    struct Placement {
        var position: CGPoint
        var anchor: UnitPoint
        var size: CGSize

        func origin(for size: CGSize) -> CGPoint {
            position - CGPoint(
                x: size.width * anchor.x,
                y: size.height * anchor.y
            )
        }

        static func filling(size: CGSize) -> Self {
            .init(
                position: .zero,
                anchor: .topLeading,
                size: size
            )
        }
    }

    /// Optional additional attributes that can be applied to a subelement.
    public struct Attributes {

        /// Corresponds to `UIView.layer.transform`.
        public var transform: CATransform3D = CATransform3DIdentity

        /// Corresponds to `UIView.alpha`.
        public var alpha: CGFloat = 1

        /// Corresponds to `UIView.isUserInteractionEnabled`.
        public var isUserInteractionEnabled: Bool = true

        /// Corresponds to `UIView.isHidden`.
        public var isHidden: Bool = false

        /// Corresponds to `UIView.tintAdjustmentMode`.
        public var tintAdjustmentMode: UIView.TintAdjustmentMode = .automatic
    }

    @propertyWrapper
    class Storage<T> {
        var wrappedValue: T

        init(wrappedValue: T) {
            self.wrappedValue = wrappedValue
        }
    }
}
