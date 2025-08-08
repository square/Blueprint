import BlueprintUI
import UIKit

/// Acts as an accessibility container for any accessible subviews.
///
/// Accessible subviews are found using the following algorithm:
///
/// Recurse subviews until a view is found that either
/// - has`isAccessibilityElement` set to `true` or
/// - returns a non-nil value from `accessibilityElements` (i.e., is a container itself)
///
/// If an accessibility element is found, we add it to the `accessibilityElements`
/// and terminate the search down that branch. If a container is found,
/// the elements returned from the container are added to the `accessibilityElements`
/// and the search down that branch is also terminated.
public struct AccessibilityContainer: Element {
    public enum ContainerType {
        case none, dataTable, list, landmark, semanticGroup
    }

    /// indicates the type of content in a data-based container.
    public var containerType: ContainerType

    /// An optional `accessibilityIdentifier` to give the container. Defaults to `nil`.
    public var identifier: String?

    /// An optional `accessibilityLabel` to give the container. Defaults to `nil`.
    public var label: String?

    /// An optional `accessibilityValue` to give the container. Defaults to `nil`.
    public var value: String?

    /// An optional array of accessibility elements, to override the wrapped children.
    public var elements: [Any]?

    public var wrapped: Element


    /// Creates a new `AccessibilityContainer` wrapping the provided element.
    public init(
        containerType: AccessibilityContainer.ContainerType = .none,
        label: String? = nil,
        value: String? = nil,
        identifier: String? = nil,
        elements: [Any]? = nil,
        wrapping element: Element
    ) {
        self.containerType = containerType
        self.label = label
        self.value = value
        self.identifier = identifier
        self.elements = elements
        wrapped = element
    }

    //
    // MARK: Element
    //

    public var content: ElementContent {
        ElementContent(child: wrapped)
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        AccessibilityContainerView.describe { config in
            config[\.accessibilityLabel] = label
            config[\.accessibilityValue] = value
            config[\.accessibilityIdentifier] = identifier
            config[\.accessibilityContainerType] = containerType.UIKitContainerType
            config[\.elements] = elements
            config[\.layoutDirection] = context.environment.layoutDirection
        }
    }
}

extension AccessibilityContainer.ContainerType {
    fileprivate var UIKitContainerType: UIAccessibilityContainerType {
        switch self {
        case .none:
            .none
        case .dataTable:
            .dataTable
        case .list:
            .list
        case .landmark:
            .landmark
        case .semanticGroup:
            .semanticGroup
        }
    }
}


extension Element {

    /// Acts as an accessibility container for any subviews
    /// where `isAccessibilityElement == true`.
    public func accessibilityContainer(
        containerType: AccessibilityContainer.ContainerType = .none,
        label: String? = nil,
        value: String? = nil,
        identifier: String? = nil
    ) -> Element {
        AccessibilityContainer(
            containerType: containerType,
            label: label,
            value: value,
            identifier: identifier,
            wrapping: self
        )
    }
}

extension AccessibilityContainer {
    internal final class AccessibilityContainerView: UIView {
        var layoutDirection: Environment.LayoutDirection = .leftToRight
        var elements: [Any]?

        override var accessibilityElements: [Any]? {
            get {
                elements ??
                    accessibilityElements(
                        layoutDirection: layoutDirection
                    )
            }
            set { fatalError("This property is not settable") }
        }
    }
}

extension UIView {
    func accessibilityElements(
        layoutDirection: Environment.LayoutDirection
    ) -> [NSObject] {
        recursiveAccessibilityElements().sorted(by: Accessibility.frameSort(
            direction: layoutDirection,
            root: self
        ))
    }

    @objc override func recursiveAccessibilityElements() -> [NSObject] {
        subviews.flatMap { subview -> [NSObject] in
            if subview.accessibilityElementsHidden || subview.isHidden {
                return []
            }

            // UICollectionView is a special case because it uses virtualization to only show a subset of its elements.
            // By doing this, we outsource the logic of specifying the accessibility elements to the collection view itself.
            // If we did not do this, we would only make the visible cells accessible, and it would prevent the user from
            // scrolling/swiping to cells outside the visible area.
            if let collectionView = subview as? UICollectionView {
                return [collectionView]
            }

            // UITableView is a similar special case as UICollectionView
            if let tableView = subview as? UITableView {
                return [tableView]
            }

            if let accessibilityElements = subview.accessibilityElements {
                return accessibilityElements.compactMap { element -> [NSObject] in
                    guard let elementObj = element as? NSObject else { return [] }

                    if elementObj.isAccessibilityElement {
                        return [elementObj]
                    }

                    return elementObj.recursiveAccessibilityElements()
                }.flatMap { $0 }
            }

            if subview.isAccessibilityElement {
                return [subview]
            }

            return subview.recursiveAccessibilityElements()
        }
    }
}

extension NSObject {
    @objc func recursiveAccessibilityElements() -> [NSObject] {
        accessibilityElements?.flatMap { element -> [NSObject] in
            guard let element = element as? NSObject else { return [] }
            if element.isAccessibilityElement {
                return [element]
            }

            return element.recursiveAccessibilityElements()
        } ?? []
    }
}
