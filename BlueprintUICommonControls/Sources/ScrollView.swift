import BlueprintUI
import UIKit


/// Wraps a content element and makes it scrollable.
public struct ScrollView: Element {

    /// The content to be scrolled.
    public var wrappedElement: Element

    /// Determines the sizing behavior of the content within the scroll view.
    public var contentSize: ContentSize = .fittingHeight
    public var alwaysBounceVertical = false
    public var alwaysBounceHorizontal = false
    public var contentInset: UIEdgeInsets = .zero
    public var centersUnderflow: Bool = false
    public var showsHorizontalScrollIndicator: Bool = true
    public var showsVerticalScrollIndicator: Bool = true
    public var pullToRefreshBehavior: PullToRefreshBehavior = .disabled
    public var keyboardDismissMode = UIScrollView.KeyboardDismissMode.none

    public init(wrapping element: Element) {
        self.wrappedElement = element
    }

    public var content: ElementContent {
        return ElementContent(child: wrappedElement, layout: layout)
    }

    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return ScrollerWrapperView.describe { config in
            config.contentView = { $0.scrollView }
            config.apply({ (view) in
                view.apply(scrollView: self, contentFrame: subtreeExtent ?? .zero)
            })
        }
    }

    private var layout: Layout {
        return Layout(
            contentInset: contentInset,
            contentSize: contentSize,
            centersUnderflow: centersUnderflow)
    }
    


}

extension ScrollView {

    fileprivate struct Layout: SingleChildLayout {

        var contentInset: UIEdgeInsets
        var contentSize: ContentSize
        var centersUnderflow: Bool

        func measure(in constraint: SizeConstraint, child: Measurable) -> CGSize {
            let adjustedConstraint = constraint.inset(
                width: contentInset.left + contentInset.right,
                height: contentInset.top + contentInset.bottom)

            var result = child.measure(in: adjustedConstraint)
            result.width += contentInset.left + contentInset.right
            result.height += contentInset.top + contentInset.bottom
            return result
        }

        func layout(size: CGSize, child: Measurable) -> LayoutAttributes {

            var insetSize = size
            insetSize.width -= contentInset.left + contentInset.right
            insetSize.height -= contentInset.top + contentInset.bottom
            var itemSize = child.measure(in: SizeConstraint(insetSize))
            if self.contentSize == .fittingHeight {
                itemSize.width = insetSize.width
            } else if self.contentSize == .fittingWidth {
                itemSize.height = insetSize.height
            }

            var contentAttributes = LayoutAttributes(frame: CGRect(origin: .zero, size: itemSize))

            if centersUnderflow {
                if contentAttributes.bounds.width < size.width {
                    contentAttributes.center.x = size.width / 2.0
                }

                if contentAttributes.bounds.height < size.height {
                    contentAttributes.center.y = size.height / 2.0
                }
            }
            return contentAttributes
        }

    }

}

extension ScrollView {

    public enum ContentSize : Equatable {

        /// The content will fill the height of the scroller, width will be dynamic
        case fittingWidth

        /// The content will fill the width of the scroller, height will be dynamic
        case fittingHeight

        /// The content size will be the minimum required to fit the content.
        case fittingContent

        /// Manually provided content size.
        case custom(CGSize)
        
    }

    public enum PullToRefreshBehavior {

        case disabled
        case enabled(action: () -> Void)
        case refreshing

        var needsRefreshControl: Bool {
            switch self {
            case .disabled:
                return false
            case .enabled, .refreshing:
                return true
            }
        }

        var isRefreshing: Bool {
            switch self {
            case .refreshing:
                return true
            case .disabled, .enabled:
                return false
            }
        }

    }

}

fileprivate final class ScrollerWrapperView: UIView {
    
    let scrollView = UIScrollView()

    private var refreshControl: UIRefreshControl? = nil {

        didSet {
            scrollView.refreshControl = refreshControl
        }

    }

    private var refreshAction: () -> Void = { }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(scrollView)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        scrollView.frame = bounds
    }

    @objc private func didPullToRefresh() {
        refreshAction()
    }

    func apply(scrollView: ScrollView, contentFrame: CGRect) {

        switch scrollView.pullToRefreshBehavior {
        case .disabled, .refreshing:
            refreshAction = { }
        case .enabled(let action):
            refreshAction = action
        }

        switch scrollView.pullToRefreshBehavior {
        case .disabled:
            refreshControl = nil
        case .enabled, .refreshing:
            if refreshControl == nil {
                let control = UIRefreshControl()
                control.addTarget(self, action: #selector(didPullToRefresh), for: .valueChanged)
                refreshControl = control
            }
        }

        if refreshControl?.isRefreshing != scrollView.pullToRefreshBehavior.isRefreshing {
            if scrollView.pullToRefreshBehavior.isRefreshing {
                refreshControl?.beginRefreshing()
            } else {
                refreshControl?.endRefreshing()
            }
        }

        let contentSize: CGSize

        switch scrollView.contentSize {
        case .fittingWidth, .fittingHeight, .fittingContent:
            contentSize = CGSize(width: contentFrame.maxX, height: contentFrame.maxY)
        case .custom(let customSize):
            contentSize = customSize
        }

        if self.scrollView.alwaysBounceHorizontal != scrollView.alwaysBounceHorizontal {
            self.scrollView.alwaysBounceHorizontal = scrollView.alwaysBounceHorizontal
        }

        if self.scrollView.alwaysBounceVertical != scrollView.alwaysBounceVertical {
            self.scrollView.alwaysBounceVertical = scrollView.alwaysBounceVertical
        }

        if self.scrollView.contentSize != contentSize {
            self.scrollView.contentSize = contentSize
        }

        if self.scrollView.showsVerticalScrollIndicator != scrollView.showsVerticalScrollIndicator {
            self.scrollView.showsVerticalScrollIndicator = scrollView.showsVerticalScrollIndicator
        }

        if self.scrollView.showsHorizontalScrollIndicator != scrollView.showsHorizontalScrollIndicator {
            self.scrollView.showsHorizontalScrollIndicator = scrollView.showsHorizontalScrollIndicator
        }

        if self.scrollView.keyboardDismissMode != scrollView.keyboardDismissMode {
            self.scrollView.keyboardDismissMode = scrollView.keyboardDismissMode
        }

        var contentInset = scrollView.contentInset

        if case .refreshing = scrollView.pullToRefreshBehavior, let refreshControl = refreshControl {
            // The refresh control lives above the content and adjusts the
            // content inset for itself when visible. Do the same adjustment to
            // our expected content inset.
            contentInset.top += refreshControl.bounds.height
        }

        if self.scrollView.contentInset != contentInset {

            let wasScrolledToTop = self.scrollView.contentOffset.y == -self.scrollView.contentInset.top
            let wasScrolledToLeft = self.scrollView.contentOffset.x == -self.scrollView.contentInset.left

            self.scrollView.contentInset = contentInset

            if wasScrolledToTop {
                self.scrollView.contentOffset.y = -contentInset.top
            }

            if wasScrolledToLeft {
                self.scrollView.contentOffset.x = -contentInset.left
            }
        }


    }

}
