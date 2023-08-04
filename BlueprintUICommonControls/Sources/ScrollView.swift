import BlueprintUI
import UIKit


/// Wraps a content element and makes it scrollable.
public struct ScrollView: Element {

    /// The content to be scrolled.
    public var wrappedElement: Element

    /// Determines the sizing behavior of the content within the scroll view.
    public var contentSize: ContentSize
    public var alwaysBounceVertical = false
    public var alwaysBounceHorizontal = false

    /**
     How much the content of the `ScrollView` should be inset.

     Note: When `keyboardAdjustmentMode` is used, it will also adjust
     the on-screen `UIScrollView`s `contentInset.bottom` to make space for the keyboard.
     */
    public var contentInset: UIEdgeInsets = .zero

    public var centersUnderflow: Bool = false
    public var showsHorizontalScrollIndicator: Bool = true
    public var showsVerticalScrollIndicator: Bool = true
    public var pullToRefreshBehavior: PullToRefreshBehavior = .disabled

    public var keyboardDismissMode: UIScrollView.KeyboardDismissMode = .none
    public var contentInsetAdjustmentBehavior: UIScrollView.ContentInsetAdjustmentBehavior = .automatic
    public var keyboardAdjustmentMode: KeyboardAdjustmentMode = .adjustsWhenVisible

    public var delaysContentTouches: Bool = true

    public var contentOffsetTrigger: ScrollTrigger?

    public init(
        _ contentSize: ContentSize = .fittingHeight,
        wrapping element: Element,
        configure: (inout ScrollView) -> Void = { _ in }
    ) {
        self.contentSize = contentSize
        wrappedElement = element

        configure(&self)
    }

    public var content: ElementContent {
        ElementContent(child: wrappedElement, layout: layout)
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        ScrollerWrapperView.describe { config in
            config.builder = {
                ScrollerWrapperView(frame: context.bounds, representedElement: self)
            }

            config.contentView = { $0.scrollView }

            config.apply {
                $0.apply(scrollView: self, contentFrame: context.subtreeExtent ?? .zero)
            }
        }
    }

    private var layout: Layout {
        Layout(
            contentInset: contentInset,
            contentSize: contentSize,
            centersUnderflow: centersUnderflow
        )
    }
}

extension Element {

    /// Wraps the element in a `ScrollView` to allow it to be scrolled
    /// if it takes up more space then is available on screen.
    public func scrollable(
        _ contentSize: ScrollView.ContentSize = .fittingHeight,
        configure: (inout ScrollView) -> Void = { _ in }
    ) -> ScrollView {
        ScrollView(
            contentSize,
            wrapping: self,
            configure: configure
        )
    }
}

extension ScrollView {

    fileprivate struct Layout: SingleChildLayout {

        var contentInset: UIEdgeInsets
        var contentSize: ContentSize
        var centersUnderflow: Bool

        func fittedSize(in constraint: SizeConstraint, child: Measurable) -> CGSize {
            switch contentSize {
            case .custom(let size):
                return size

            case .fittingContent:
                return child.measure(in: .unconstrained)

            case .fittingHeight:
                return child.measure(
                    in: SizeConstraint(
                        width: constraint.width,
                        height: .unconstrained
                    ))

            case .fittingWidth:
                return child.measure(
                    in: SizeConstraint(
                        width: .unconstrained,
                        height: constraint.height
                    ))
            }
        }

        func measure(in constraint: SizeConstraint, child: Measurable) -> CGSize {
            let adjustedConstraint = constraint.inset(
                width: contentInset.left + contentInset.right,
                height: contentInset.top + contentInset.bottom
            )

            var result = fittedSize(in: adjustedConstraint, child: child)

            result.width += contentInset.left + contentInset.right
            result.height += contentInset.top + contentInset.bottom

            result.width = min(result.width, constraint.width.maximum)
            result.height = min(result.height, constraint.height.maximum)

            return result
        }

        func layout(size: CGSize, child: Measurable) -> LayoutAttributes {

            var insetSize = size
            insetSize.width -= contentInset.left + contentInset.right
            insetSize.height -= contentInset.top + contentInset.bottom

            var itemSize = fittedSize(in: SizeConstraint(insetSize), child: child)
            if contentSize == .fittingHeight {
                itemSize.width = insetSize.width
            } else if contentSize == .fittingWidth {
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

        func fittedSize(in proposal: SizeConstraint, subelement: Subelement) -> CGSize {
            switch contentSize {
            case .custom(let size):
                return size

            case .fittingContent:
                return subelement.sizeThatFits(.unconstrained)

            case .fittingHeight:
                return subelement.sizeThatFits(
                    SizeConstraint(
                        width: proposal.width,
                        height: .unconstrained
                    )
                )

            case .fittingWidth:
                return subelement.sizeThatFits(
                    SizeConstraint(
                        width: .unconstrained,
                        height: proposal.height
                    )
                )
            }
        }

        func sizeThatFits(
            proposal: SizeConstraint,
            subelement: Subelement,
            environment: Environment,
            cache: inout Cache
        ) -> CGSize {
            let adjustedProposal = proposal.inset(by: contentInset)

            var result = fittedSize(in: adjustedProposal, subelement: subelement)

            result.width += contentInset.left + contentInset.right
            result.height += contentInset.top + contentInset.bottom

            if let maxWidth = proposal.width.constrainedValue {
                result.width = min(result.width, maxWidth)
            }
            if let maxHeight = proposal.height.constrainedValue {
                result.height = min(result.height, maxHeight)
            }

            return result
        }

        func placeSubelement(
            in size: CGSize,
            subelement: Subelement,
            environment: Environment,
            cache: inout ()
        ) {
            var insetSize = size
            insetSize.width -= contentInset.left + contentInset.right
            insetSize.height -= contentInset.top + contentInset.bottom

            var itemSize = fittedSize(in: .init(insetSize), subelement: subelement)
                .replacingInfinity(with: insetSize)

            if contentSize == .fittingHeight {
                itemSize.width = insetSize.width
            } else if contentSize == .fittingWidth {
                itemSize.height = insetSize.height
            }

            var origin: CGPoint = .zero

            if centersUnderflow {
                if itemSize.width < size.width {
                    origin.x += (size.width - itemSize.width) / 2
                }

                if itemSize.height < size.height {
                    origin.y += (size.height - itemSize.height) / 2
                }
            }

            subelement.place(at: origin, size: itemSize)
        }
    }

}

extension ScrollView {

    public enum KeyboardAdjustmentMode: Equatable {
        case none
        case adjustsWhenVisible
    }

    public enum ContentSize: Equatable {

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
    let keyboardObserver = KeyboardObserver.shared

    /// The current `ScrollView` state we represent.
    private var representedElement: ScrollView

    private var refreshControl: UIRefreshControl? = nil {

        didSet {
            scrollView.refreshControl = refreshControl
        }

    }

    private var refreshAction: () -> Void = {}

    private var contentOffsetTrigger: ScrollView.ScrollTrigger? {
        didSet {
            oldValue?.action = { _, _ in }
            contentOffsetTrigger?.action = { [weak self] offset, animated in
                guard let self = self else { return }

                let context = ScrollView.ContentOffset.ScrollingContext(
                    contentSize: self.scrollView.contentSize,
                    scrollViewBounds: self.scrollView.bounds,
                    contentInsets: self.scrollView.contentInset
                )
                self.scrollView.setContentOffset(offset.provider(context), animated: animated)
            }
        }
    }

    init(frame: CGRect, representedElement: ScrollView) {

        self.representedElement = representedElement

        super.init(frame: frame)

        keyboardObserver.add(delegate: self)

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

        representedElement = scrollView

        switch scrollView.pullToRefreshBehavior {
        case .disabled, .refreshing:
            refreshAction = {}
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

        if self.scrollView.delaysContentTouches != scrollView.delaysContentTouches {
            self.scrollView.delaysContentTouches = scrollView.delaysContentTouches
        }

        if self.scrollView.contentInsetAdjustmentBehavior != scrollView.contentInsetAdjustmentBehavior {
            self.scrollView.contentInsetAdjustmentBehavior = scrollView.contentInsetAdjustmentBehavior
        }

        contentOffsetTrigger = scrollView.contentOffsetTrigger

        applyContentInset(with: scrollView)
    }

    private func applyContentInset(with scrollView: ScrollView) {
        let contentInset = ScrollView.calculateContentInset(
            scrollViewInsets: scrollView.contentInset,
            safeAreaInsets: safeAreaInsets,
            keyboardBottomInset: bottomContentInsetAdjustmentForKeyboard,
            refreshControlState: scrollView.pullToRefreshBehavior,
            refreshControlBounds: refreshControl?.bounds
        )

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

    //
    // MARK: UIView
    //

    public override func didMoveToWindow() {
        super.didMoveToWindow()

        if window != nil {
            updateBottomContentInsetWithKeyboardFrame()
        }
    }

    public override func didMoveToSuperview() {
        super.didMoveToSuperview()

        if superview != nil {
            updateBottomContentInsetWithKeyboardFrame()
        }
    }
}


extension ScrollView {
    // Calculates the correct content inset to apply for the given inputs.

    static func calculateContentInset(
        scrollViewInsets: UIEdgeInsets,
        safeAreaInsets: UIEdgeInsets,
        keyboardBottomInset: CGFloat,
        refreshControlState: PullToRefreshBehavior,
        refreshControlBounds: CGRect?
    ) -> UIEdgeInsets {
        var finalContentInset = scrollViewInsets

        // Include the keyboard's adjustment at the bottom of the scroll view.

        if keyboardBottomInset > 0.0 {
            finalContentInset.bottom += keyboardBottomInset

            // Exclude the safe area insets, so the content hugs the top of the keyboard.

            finalContentInset.bottom -= safeAreaInsets.bottom
        }

        return finalContentInset
    }
}


extension ScrollerWrapperView: KeyboardObserverDelegate {

    //
    // MARK: Keyboard
    //

    private func updateBottomContentInsetWithKeyboardFrame() {

        let contentInset = ScrollView.calculateContentInset(
            scrollViewInsets: representedElement.contentInset,
            safeAreaInsets: safeAreaInsets,
            keyboardBottomInset: bottomContentInsetAdjustmentForKeyboard,
            refreshControlState: representedElement.pullToRefreshBehavior,
            refreshControlBounds: refreshControl?.bounds
        )

        /// Setting contentInset, even to the same value, can cause issues during scrolling (such as stopping scrolling).
        /// Make sure we're only assigning the value if it changed.

        if scrollView.contentInset.bottom != contentInset.bottom {
            scrollView.contentInset.bottom = contentInset.bottom
        }

        if scrollView.verticalScrollIndicatorInsets.bottom != contentInset.bottom {
            scrollView.verticalScrollIndicatorInsets.bottom = contentInset.bottom
        }
    }

    fileprivate var bottomContentInsetAdjustmentForKeyboard: CGFloat {

        switch representedElement.keyboardAdjustmentMode {
        case .none:
            return 0.0

        case .adjustsWhenVisible:
            guard let keyboardFrame = keyboardObserver.currentFrame(in: self) else {
                return 0.0
            }

            switch keyboardFrame {
            case .nonOverlapping: return 0.0
            case .overlapping(let frame): return bounds.size.height - frame.origin.y
            }
        }
    }

    //
    // MARK: KeyboardObserverDelegate
    //

    func keyboardFrameWillChange(
        for observer: KeyboardObserver,
        animationDuration: Double,
        animationCurve: UIView.AnimationCurve
    ) {
        UIViewPropertyAnimator(duration: animationDuration, curve: animationCurve) {
            self.updateBottomContentInsetWithKeyboardFrame()
        }
        .startAnimation()
    }
}


extension ScrollView {

    public final class ScrollTrigger {

        var action: (ContentOffset, Bool) -> Void

        public init() {
            action = { _, _ in }
        }

        public func scroll(to: ContentOffset, animated: Bool) {
            action(to, animated)
        }
    }

    public struct ContentOffset {

        public struct ScrollingContext {
            public var contentSize: CGSize
            public var scrollViewBounds: CGRect
            public var contentInsets: UIEdgeInsets
        }

        public typealias Provider = (ScrollingContext) -> CGPoint

        public static let top = ContentOffset { _ in .zero }
        public static let bottom = ContentOffset { context in
            CGPoint(
                x: 0,
                y: context.contentSize.height - context.scrollViewBounds.size.height + context.contentInsets.bottom
            )
        }

        var provider: Provider

        public init(provider: @escaping Provider) {
            self.provider = provider
        }
    }
}
