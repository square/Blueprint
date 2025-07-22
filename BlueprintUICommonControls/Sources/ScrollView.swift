import BlueprintUI
import UIKit


/// Wraps a content element and makes it scrollable.
public struct ScrollView: Element {

    /// The content to be scrolled.
    public var wrappedElement: Element

    /// Determines the sizing behavior of the content within the scroll view.
    public var contentSize: ContentSize

    /// When true, the content will bounce even when it is less than or equal to the height
    /// of the `UIScrollView`.
    public var alwaysBounceVertical = false

    /// When true, the content will bounce even when it is less than or equal to the width
    /// of the `UIScrollView`.
    public var alwaysBounceHorizontal = false

    /// This controls how the scroll view treats the safe areas when the content size is
    /// less than the length of the scroll view's scrollable axes, but greater than the
    /// safe area size.
    ///
    /// > This is only used when `contentInsetAdjustmentBehavior` is `scrollableAxes`.
    public var contentSafeAreaOverlapBehavior: ContentSafeAreaOverlapBehavior = .ignoreSafeArea

    public enum ContentSafeAreaOverlapBehavior {
        /// Safe areas are respected when the content overlaps them. This is done by
        /// conditionally setting the `alwaysBounceVertical` and/or `alwaysBounceHorizontal`
        /// options to `true` on the underlying `UIScrollView`.
        case includeSafeArea

        /// Safe areas are ignored when the content overlaps them. This is the default
        /// UIKit behavior when using `ContentInsetAdjustmentBehavior.scrollableAxes`.
        case ignoreSafeArea
    }

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

            let contentFrame = context.subtreeExtent ?? .zero

            config.applyBeforeLayout { view in

                /// We apply the `contentSize` before the `LayoutAttributes` because order of operations matters
                /// when adjusting the size of the scroll view's frame and the content size. If we set the frame before
                /// setting the content size – in particular making the frame taller before adjusting the content size,
                /// the scroll view will internally adjust the `contentOffset`, resulting in the on-screen content
                /// jumping around.
                ///
                /// This is most visible and annoying when you have a scroll view in a resizable modal, which is scrolled away
                /// from the top of its content. If the size of the scroll view grows before the `contentSize` is adjusted,
                /// the visible content will shift.
                ///
                ///
                /// The `contentFrame` is not inset for the safe area. The `contentFrame` width and height will vary
                /// depending upon the setting for `self.contentSize`:
                /// - `fittingWidth` will use a height equal to ScrollView's frame height. This height may overlap the
                /// vertical safe area, but it will not extend beyond the vertical bounds of the scroll view.
                /// - `fittingHeight` will use width equal to ScrollView's frame width. This width may overlap the horizontal
                /// safe area, but it will not extend beyond the horizontal bounds of the scroll view.
                /// - `fittingContent` will use a `contentFrame` exactly equal to the size of the content. Depending on the
                /// content measurement, this may extend beyond the safe area.
                /// - `custom(_:)` will use a `contentFrame` exactly equal to the provided size. Depending on the content
                /// measurement, this may extend beyond the safe area.
                ///
                /// Using `ContentInsetAdjustmentBehavior.always` may eagerly enable scrolling along an an unexpected axis,
                /// like enabling horizontal scrolling in landscape when using `fittingHeight`, since the content may extend
                /// into the horizontal safe area. Using `.scrollableAxes` works around this.

                let contentSize = switch contentSize {
                case .fittingWidth, .fittingHeight, .fittingContent:
                    CGSize(width: contentFrame.maxX, height: contentFrame.maxY)
                case .custom(let custom):
                    custom
                }

                if view.scrollView.contentSize != contentSize {
                    view.scrollView.contentSize = contentSize
                }
            }

            config.apply { view in
                view.apply(scrollView: self, contentFrame: contentFrame)
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

    /// The current frame of the content within `ScrollView`. This is nil until
    /// `apply(scrollView:contentFrame:)` is called.
    private var contentFrame: CGRect?

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

    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        guard let contentFrame else { return }

        // When the safe area insets change, we need to determine if the content
        // overlaps the safe area without extending beyond the scroll view frame.
        processScrollableAxesSafeAreaOverlap(
            scrollView: representedElement,
            contentFrame: contentFrame
        )
    }

    func apply(scrollView: ScrollView, contentFrame: CGRect) {

        representedElement = scrollView
        self.contentFrame = contentFrame

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

        processScrollableAxesSafeAreaOverlap(
            scrollView: scrollView,
            contentFrame: contentFrame
        )

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

    /// When using both `ContentInsetAdjustmentBehavior.scrollableAxes` and
    /// `ContentSafeAreaOverlapBehavior.includeSafeArea` together, this function will
    /// determine if the scrollable content is less than the bounds of the scroll view,
    /// but larger than the safe area. In those cases, axis bouncing is enabled so that
    /// the safe area insets are included in the content inset.
    /// - Parameters:
    ///   - scrollView: The `ScrollView` that is being drawn.
    ///   - contentFrame: The frame of the `ScrollView`'s content.
    func processScrollableAxesSafeAreaOverlap(scrollView: ScrollView, contentFrame: CGRect) {

        guard scrollView.contentInsetAdjustmentBehavior == .scrollableAxes,
              scrollView.contentSafeAreaOverlapBehavior == .includeSafeArea
        else {
            applyStandardVerticalBounceBehavior()
            applyStandardHorizontalBounceBehavior()
            return
        }

        let verticalBoundsRect = CGRect(
            x: contentFrame.origin.x,
            y: bounds.origin.y,
            width: contentFrame.width,
            height: bounds.height
        )
        let verticalSafeAreaRect = CGRect(
            x: contentFrame.origin.x,
            y: safeAreaLayoutGuide.layoutFrame.origin.y,
            width: contentFrame.width,
            height: safeAreaLayoutGuide.layoutFrame.height - scrollView.contentInset.top - scrollView.contentInset.bottom
        )
        // Check if the content is vertically within the scroll view, but outside of the safe area.
        if verticalBoundsRect.contains(contentFrame) && !verticalSafeAreaRect.contains(contentFrame) {
            if self.scrollView.alwaysBounceVertical != true {
                self.scrollView.alwaysBounceVertical = true
            }
        } else {
            applyStandardVerticalBounceBehavior()
        }

        let horizontalBoundsRect = CGRect(
            x: bounds.origin.x,
            y: contentFrame.origin.y,
            width: bounds.width,
            height: contentFrame.height
        )
        let horizontalSafeAreaRect = CGRect(
            x: safeAreaLayoutGuide.layoutFrame.origin.x,
            y: contentFrame.origin.y,
            width: safeAreaLayoutGuide.layoutFrame.width - scrollView.contentInset.left - scrollView.contentInset.right,
            height: contentFrame.height
        )
        // Check if the content is horizontally within the scroll view, but outside the safe area.
        if horizontalBoundsRect.contains(contentFrame) && !horizontalSafeAreaRect.contains(contentFrame) {
            if self.scrollView.alwaysBounceHorizontal != true {
                self.scrollView.alwaysBounceHorizontal = true
            }
        } else {
            applyStandardHorizontalBounceBehavior()
        }

        /// This pulls the `alwaysBounceVertical` setting from `scrollView`.
        func applyStandardVerticalBounceBehavior() {
            if self.scrollView.alwaysBounceVertical != scrollView.alwaysBounceVertical {
                self.scrollView.alwaysBounceVertical = scrollView.alwaysBounceVertical
            }
        }

        /// This pulls the `alwaysBounceHorizontal` setting from `scrollView`.
        func applyStandardHorizontalBounceBehavior() {
            if self.scrollView.alwaysBounceHorizontal != scrollView.alwaysBounceHorizontal {
                self.scrollView.alwaysBounceHorizontal = scrollView.alwaysBounceHorizontal
            }
        }
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
        //
        // We check for values over 1.0 because of how BlueprintView rounds its root node's
        // frame. This rounding can increase a view's frame so that it extends slightly
        // offscreen. For example, a view height of 715.51 on a 3x device is rounded to a
        // height of 715.66. If this view is anchored to the bottom of the screen, it will
        // technically overlap the dismissed keyboard by 0.15pts. We filter out these cases.

        if keyboardBottomInset > 1.0 {
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
