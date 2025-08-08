import BlueprintUI
import UIKit

extension Element {
    /// Adds large content viewer support to an individual element. Ensure that you use this in conjunction with accessibilityLargeContentViewerInteractionContainer().
    ///
    /// Large content viewer allows users to see a larger version of content when they press and hold
    /// on small UI elements. This is particularly useful for users who are low vision.
    /// It must only be used if dynamic type is not an option for a given element; it must not be used as a substitute for dynamic type.
    /// It's triggered by a long press gesture and shows an enlarged version of the content in a special overlay.
    /// It's only available when accessibility system type sizes.
    ///
    /// - Parameters:
    ///   - title: The title to display in the large content viewer. Defaults to nil.
    ///   - image: The image to display in the large content viewer. Defaults to nil.
    ///   - scalesLargeContentImage: Whether the image should be scaled in the large content viewer. Defaults to false.
    ///   - largeContentImageInsets: The insets to apply to the large content image. Defaults to zero insets.
    ///
    public func accessibilityShowsLargeContentViewer(
        display: Accessibility.LargeContentViewerConfiguration.Display,
        scalesLargeContentImage: Bool = false,
        largeContentImageInsets: UIEdgeInsets = .zero,
        interactionEndedCallback: ((CGPoint) -> Void)? = nil
    ) -> Element {
        Accessibility.LargeContentViewer(
            wrapping: self,
            configuration: .init(
                display: display,
                scalesLargeContentImage: scalesLargeContentImage,
                largeContentImageInsets: largeContentImageInsets,
                interactionEndedCallback: interactionEndedCallback
            )
        )
    }
}

extension Accessibility {

    /// Enables an element to opt-in to Large content viewer accessibility support. For a given
    /// element, add conformance to this protocol and provide the `largeContentViewerConfiguration` to
    /// automatically provide the large content viewer behavior without having to manually supply the arguments
    /// every time an instance of the element is defined.
    ///
    /// Large content viewer allows users to see a larger version of content when they press and hold
    /// on small UI elements. This is particularly useful for users who are low vision.
    /// It must only be used if dynamic type is not an option for a given element; it must not be used as a substitute for dynamic type.
    /// It's triggered by a long press gesture and shows an enlarged version of the content in a special overlay.
    /// It's only available when accessibility system type sizes.
    ///
    /// If your element can function as a large content viewer element, add conformance to this protocol to
    /// add large content viewer behavior via `accessibilityShowsLargeContentViewer()`.
    public protocol LargeContentViewerElement: Element {

        /// Returns the large content viewer configuration for this element.
        var largeContentViewerConfiguration: LargeContentViewerConfiguration { get }
    }
}


extension Accessibility.LargeContentViewerElement {

    /// Enables large content viewer for the provided element.
    public func accessibilityShowsLargeContentViewer() -> Element {
        Accessibility.LargeContentViewer(wrapping: self, configuration: largeContentViewerConfiguration)
    }
}

extension Accessibility {
    /// Large content viewer allows users to see a larger version of content when they press and hold
    /// on small UI elements. This is particularly useful for users who have difficulty seeing small text or icons.
    public protocol LargeContentViewerItem: UIView {
        var largeContentViewerConfiguration: LargeContentViewerConfiguration { get }

        func didEndInteraction(at location: CGPoint, root: UICoordinateSpace)
    }
}

extension Accessibility {
    public struct LargeContentViewerConfiguration {

        public enum Display: Equatable {
            case title(String, UIImage?)
            case image(UIImage)
            case none
        }

        /// Title and/or image to display in the large content viewer.
        public var display: Display

        /// Whether the image should be scaled in the large content viewer.
        public var scalesLargeContentImage: Bool

        /// The insets to apply to the large content image.
        public var largeContentImageInsets: UIEdgeInsets

        /// The callback to be called when the interaction ends on this item.
        /// The point (within the coordinate space of the element) at which the interaction ended is provided as the argument.
        public var interactionEndedCallback: ((CGPoint) -> Void)?

        public init(
            display: Display,
            scalesLargeContentImage: Bool = false,
            largeContentImageInsets: UIEdgeInsets = .zero,
            interactionEndedCallback: ((CGPoint) -> Void)? = nil
        ) {
            self.display = display
            self.scalesLargeContentImage = scalesLargeContentImage
            self.largeContentImageInsets = largeContentImageInsets
            self.interactionEndedCallback = interactionEndedCallback
        }
    }
}

extension Accessibility {

    public struct LargeContentViewer: Element {

        var wrapping: Element

        var configuration: LargeContentViewerConfiguration

        public var content: ElementContent {
            ElementContent(child: wrapping)
        }

        public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
            LargeContentViewerView.describe { config in
                config[\.largeContentViewerConfiguration] = configuration
            }
        }
    }
}

extension Accessibility {

    private final class LargeContentViewerView: UIView, LargeContentViewerItem {

        var largeContentViewerConfiguration: LargeContentViewerConfiguration {
            didSet {
                updateLargeContentViewerItem()
            }
        }

        override init(frame: CGRect) {
            largeContentViewerConfiguration = .init(display: .none)
            super.init(frame: frame)
            showsLargeContentViewer = false
            updateLargeContentViewerItem()
        }

        required init?(coder: NSCoder) {
            largeContentViewerConfiguration = .init(display: .none)
            super.init(coder: coder)
            showsLargeContentViewer = false
            updateLargeContentViewerItem()
        }

        private func updateLargeContentViewerItem() {
            scalesLargeContentImage = largeContentViewerConfiguration.scalesLargeContentImage
            largeContentImageInsets = largeContentViewerConfiguration.largeContentImageInsets

            switch largeContentViewerConfiguration.display {
            case .title(let title, let image):
                showsLargeContentViewer = true
                largeContentTitle = title
                largeContentImage = image
            case .image(let image):
                showsLargeContentViewer = true
                largeContentTitle = nil
                largeContentImage = image
            case .none:
                showsLargeContentViewer = false
                largeContentTitle = nil
                largeContentImage = nil
            }
        }

        func didEndInteraction(at location: CGPoint, root: UICoordinateSpace) {
            largeContentViewerConfiguration.interactionEndedCallback?(convert(location, from: root))
        }
    }
}

// MARK: - Large content viewer container

extension Element {

    /// Adds a large content viewer interaction container to the element.
    /// This is used to wrap elements that need to be able to show a large content viewer.
    /// Use this in conjunction with accessibilityShowsLargeContentViewer() on elements that need to show a large content viewer.
    /// Elements that are wrapped in this container will be able to show a large content viewer and allow a user to swipe through them with one finger
    /// and have the HUD update in real time.
    public func accessibilityLargeContentViewerInteractionContainer() -> Element {
        Accessibility.LargeContentViewerInteractionContainer(wrapping: self)
    }
}

extension Accessibility {

    public struct LargeContentViewerInteractionContainer: Element {

        var wrapping: Element

        public var content: ElementContent {
            ElementContent(child: wrapping)
        }

        public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
            LargeContentViewerInteractionContainerView.describe { _ in }
        }
    }
}

extension Accessibility {

    private final class LargeContentViewerInteractionContainerView: UIView, UILargeContentViewerInteractionDelegate {

        var largeContentViewerInteraction: UILargeContentViewerInteraction?

        public override func didMoveToWindow() {
            super.didMoveToWindow()
            if window != nil {
                let largeContentViewerInteraction = UILargeContentViewerInteraction(delegate: self)
                addInteraction(largeContentViewerInteraction)
                self.largeContentViewerInteraction = largeContentViewerInteraction
            }
        }

        // MARK: UILargeContentViewerInteractionDelegate

        public func largeContentViewerInteraction(
            _ interaction: UILargeContentViewerInteraction,
            didEndOn item: (any UILargeContentViewerItem)?,
            at point: CGPoint
        ) {
            if let largeContentItem = item as? Accessibility.LargeContentViewerItem {
                largeContentItem.didEndInteraction(at: point, root: self)
            }
        }
    }
}

