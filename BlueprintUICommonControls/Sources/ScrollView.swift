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

    /// This controls which edges of the safe area that the `ScrollView` inspects for
    /// overhanging content when using `ContentInsetAdjustmentBehavior.scrollableAxes`.
    /// This will ensure that the provided edges are always scrollable when overhanging
    /// the safe area.
    ///
    /// The default value is the empty set, which leverages standard UIKit behavior.
    public var scrollableAxesSafeAreaEdges: SafeAreaEdge = [] {
        didSet {
            didModifyScrollableAxesSafeAreaEdges = true
        }
    }

    /// Determines whether `scrollableAxesSafeAreaEdges` has been modified by the
    /// client or not.
    public private(set) var didModifyScrollableAxesSafeAreaEdges: Bool = false

    /// This model represents the various edges of the `ScrollView` safe area.
    public struct SafeAreaEdge: OptionSet {

        public let rawValue: UInt8

        public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }

        public static let top = SafeAreaEdge(rawValue: 1)
        public static let left = SafeAreaEdge(rawValue: 1 << 1)
        public static let bottom = SafeAreaEdge(rawValue: 1 << 2)
        public static let right = SafeAreaEdge(rawValue: 1 << 3)

        public static let all: Self = [.top, .left, .bottom, .right]
        public static let horizontal: Self = [.left, .right]
        public static let vertical: Self = [.top, .bottom]

        var isHorizontal: Bool {
            SafeAreaEdge.horizontal.contains(self)
        }

        var isVertical: Bool {
            SafeAreaEdge.vertical.contains(self)
        }
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
                /// The `contentFrame` is not inset for the safe area. The `contentFrame` width and height will vary depending
                /// upon the setting for `self.contentSize`. For instance, `fittingHeight` will use a width equal to the
                /// scroll view's frame width. This width may overhang the horizontal safe area, but it will not extend beyond
                /// the horizontal bounds of the scroll view.
                ///
                /// Using `ContentInsetAdjustmentBehavior.always` may eagerly enable scrolling along an unexpected axis, like
                /// enabling horizontal scrolling in landscape when using `fittingHeight`. This is because the content may extend
                /// beyond the horizontal safe area while still residing inside the bounds. The `scrollableAxes` behavior is
                /// used to avoid this.

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

    /// Represents how each edge overflows or underflows the safe area and the scroll
    /// view bounds. This is only used with `ContentInsetAdjustmentBehavior.scrollableAxes`.
    private var contentEdgeConfigurations: ContentEdgeConfigurations = .none

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

        processScrollableAxesEdgeConfigurations()
        applyContentInset()
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

        if self.scrollView.alwaysBounceHorizontal != scrollView.alwaysBounceHorizontal {
            self.scrollView.alwaysBounceHorizontal = scrollView.alwaysBounceHorizontal
        }

        if self.scrollView.alwaysBounceVertical != scrollView.alwaysBounceVertical {
            self.scrollView.alwaysBounceVertical = scrollView.alwaysBounceVertical
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

        processScrollableAxesEdgeConfigurations()

        contentOffsetTrigger = scrollView.contentOffsetTrigger

        applyContentInset()
    }

    /// This function will calculate how each edge of the content overflows or underflows
    /// the safe area and scroll view bounds.
    func processScrollableAxesEdgeConfigurations() {
        guard let contentFrame,
              representedElement.contentInsetAdjustmentBehavior == .scrollableAxes,
              !representedElement.scrollableAxesSafeAreaEdges.isEmpty
        else {
            contentEdgeConfigurations = .none
            return
        }

        /// Executes the `compute` handler if the `edge` is included in the option set.
        func calculateConfiguration(edge: ScrollView.SafeAreaEdge, compute: () -> (ContentEdgeConfiguration)) -> ContentEdgeConfiguration {
            guard representedElement.scrollableAxesSafeAreaEdges.contains(edge) else {
                return .none
            }
            // UIKit will always honor safe areas when using bouncing.
            if edge.isVertical && representedElement.alwaysBounceVertical {
                return .none
            } else if edge.isHorizontal && representedElement.alwaysBounceHorizontal {
                return .none
            }
            return compute()
        }

        let topConfiguration = calculateConfiguration(edge: .top) {
            ScrollView.calculateEdgeConfiguration(
                contentMinEdge: contentFrame.minY,
                safeAreaMinEdge: safeAreaLayoutGuide.layoutFrame.minY,
                boundsMinEdge: bounds.minY
            )
        }
        let leftConfiguration = calculateConfiguration(edge: .left) {
            ScrollView.calculateEdgeConfiguration(
                contentMinEdge: contentFrame.minX,
                safeAreaMinEdge: safeAreaLayoutGuide.layoutFrame.minX,
                boundsMinEdge: bounds.minX
            )
        }
        let bottomConfiguration = calculateConfiguration(edge: .bottom) {
            let topInset = topConfiguration == .overflowsSafeArea ? safeAreaInsets.top : 0
            return ScrollView.calculateEdgeConfiguration(
                contentMaxEdge: contentFrame.maxY,
                // The bottom calculation needs to account for the top adjustment.
                adjustedMaxEdge: contentFrame.maxY + topInset,
                safeAreaMaxEdge: safeAreaLayoutGuide.layoutFrame.maxY,
                boundsMaxEdge: bounds.maxY
            )
        }
        let rightConfiguration = calculateConfiguration(edge: .right) {
            let leftInset = leftConfiguration == .overflowsSafeArea ? safeAreaInsets.left : 0
            return ScrollView.calculateEdgeConfiguration(
                contentMaxEdge: contentFrame.maxX,
                // The right calculation needs to account for the left adjustment.
                adjustedMaxEdge: contentFrame.maxX + leftInset,
                safeAreaMaxEdge: safeAreaLayoutGuide.layoutFrame.maxX,
                boundsMaxEdge: bounds.maxX
            )
        }

        contentEdgeConfigurations = .init(
            top: topConfiguration,
            left: leftConfiguration,
            bottom: bottomConfiguration,
            right: rightConfiguration
        )
    }

    private func applyContentInset() {
        let (contentInset, indicatorBottomInset) = ScrollView.calculateContentInset(
            scrollViewInsets: scrollViewInsets,
            safeAreaInsets: safeAreaInsets,
            keyboardBottomInset: bottomContentInsetAdjustmentForKeyboard,
            bottomEdgeConfiguration: contentEdgeConfigurations.bottom
        )

        if scrollView.contentInset != contentInset {

            let wasScrolledToTop = scrollView.contentOffset.y == -scrollView.contentInset.top
            let wasScrolledToLeft = scrollView.contentOffset.x == -scrollView.contentInset.left

            scrollView.contentInset = contentInset

            if wasScrolledToTop {
                scrollView.contentOffset.y = -contentInset.top
            }

            if wasScrolledToLeft {
                scrollView.contentOffset.x = -contentInset.left
            }
        }

        if scrollView.verticalScrollIndicatorInsets.bottom != indicatorBottomInset {
            scrollView.verticalScrollIndicatorInsets.bottom = indicatorBottomInset
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

    /// Calculates the `ContentEdgeConfiguration` for either the top or left
    /// content edge.
    static func calculateEdgeConfiguration(
        contentMinEdge: CGFloat,
        safeAreaMinEdge: CGFloat,
        boundsMinEdge: CGFloat
    ) -> ContentEdgeConfiguration {
        if contentMinEdge < boundsMinEdge {
            return .overflowsBounds
        } else if contentMinEdge < safeAreaMinEdge {
            return .overflowsSafeArea
        } else {
            return .underflowsSafeArea
        }
    }

    /// Calculates the `ContentEdgeConfiguration` for either the right or bottom
    /// content edge.
    static func calculateEdgeConfiguration(
        contentMaxEdge: CGFloat,
        adjustedMaxEdge: CGFloat,
        safeAreaMaxEdge: CGFloat,
        boundsMaxEdge: CGFloat
    ) -> ContentEdgeConfiguration {
        if contentMaxEdge > boundsMaxEdge {
            return .overflowsBounds
        } else if adjustedMaxEdge > safeAreaMaxEdge {
            return .overflowsSafeArea
        } else {
            return .underflowsSafeArea
        }
    }

    /// Calculates the correct content inset to apply for the given inputs. This also returns
    /// the appropriate indicator bottom inset to apply.
    static func calculateContentInset(
        scrollViewInsets: UIEdgeInsets,
        safeAreaInsets: UIEdgeInsets,
        keyboardBottomInset: CGFloat,
        bottomEdgeConfiguration: ContentEdgeConfiguration
    ) -> (contentInset: UIEdgeInsets, indicatorBottomInset: CGFloat) {
        var finalContentInset = scrollViewInsets

        // Include the keyboard's adjustment at the bottom of the scroll view.
        //
        // We check for values over 1.0 because of how BlueprintView rounds its root node's
        // frame. This rounding can increase a view's frame so that it extends slightly
        // offscreen. For example, a view height of 715.51 on a 3x device is rounded to a
        // height of 715.66. If this view is anchored to the bottom of the screen, it will
        // technically overlap the dismissed keyboard by 0.15pts. We filter out these cases.

        if keyboardBottomInset > max(1.0, safeAreaInsets.bottom) {
            finalContentInset.bottom += keyboardBottomInset

            switch bottomEdgeConfiguration {
            case .none, .overflowsSafeArea, .overflowsBounds:
                // Exclude the safe area insets, so the content hugs the top of the keyboard.
                finalContentInset.bottom -= safeAreaInsets.bottom
            case .underflowsSafeArea:
                // If content doesn't reach the safe area, we don't want to remove the safe
                // area from this inset because that would cause content to become unreachable
                // under the keyboard.
                break
            }
        }

        let finalIndicatorBottomInset: CGFloat
        switch bottomEdgeConfiguration {
        case .none:
            finalIndicatorBottomInset = finalContentInset.bottom
        case .underflowsSafeArea:
            // When underflowing, we want to exclude the safe area inset, otherwise the
            // indicator will be reduced too far. This particular case only goes into
            // effect when the keyboard is on screen.
            finalIndicatorBottomInset = finalContentInset.bottom - safeAreaInsets.bottom
        case .overflowsSafeArea:
            // Subtract the safe area to avoid it being included twice.
            finalIndicatorBottomInset = finalContentInset.bottom - safeAreaInsets.bottom
        case .overflowsBounds:
            finalIndicatorBottomInset = finalContentInset.bottom
        }

        return (finalContentInset, finalIndicatorBottomInset)
    }
}

enum ContentEdgeConfiguration {
    /// This edge is excluded from calculations.
    case none

    /// Content is smaller than the safe area edge.
    case underflowsSafeArea

    /// Content overflows the safe area but underflows the scroll view bounds.
    case overflowsSafeArea

    /// Content overflows the edge of the scroll view bounds.
    case overflowsBounds
}

struct ContentEdgeConfigurations {
    var top: ContentEdgeConfiguration
    var left: ContentEdgeConfiguration
    var bottom: ContentEdgeConfiguration
    var right: ContentEdgeConfiguration

    static var none: Self {
        ContentEdgeConfigurations(
            top: .none,
            left: .none,
            bottom: .none,
            right: .none
        )
    }
}

extension ScrollerWrapperView: KeyboardObserverDelegate {

    //
    // MARK: Keyboard
    //

    /// The minimal insets that should be applied to the scroll view.
    var scrollViewInsets: UIEdgeInsets {
        UIEdgeInsets(
            top: representedElement.contentInset.top + (contentEdgeConfigurations.top == .overflowsSafeArea ? safeAreaInsets.top : 0),
            left: representedElement.contentInset.left + (contentEdgeConfigurations.left == .overflowsSafeArea ? safeAreaInsets.left : 0),
            bottom: representedElement.contentInset.bottom + (contentEdgeConfigurations.bottom == .overflowsSafeArea ? safeAreaInsets.bottom : 0),
            right: representedElement.contentInset.right + (contentEdgeConfigurations.right == .overflowsSafeArea ? safeAreaInsets.right : 0)
        )
    }

    private func updateBottomContentInsetWithKeyboardFrame() {
        let (contentInset, indicatorBottomInset) = ScrollView.calculateContentInset(
            scrollViewInsets: scrollViewInsets,
            safeAreaInsets: safeAreaInsets,
            keyboardBottomInset: bottomContentInsetAdjustmentForKeyboard,
            bottomEdgeConfiguration: contentEdgeConfigurations.bottom
        )

        /// Setting contentInset, even to the same value, can cause issues during scrolling (such as stopping scrolling).
        /// Make sure we're only assigning the value if it changed.

        if scrollView.contentInset.bottom != contentInset.bottom {
            scrollView.contentInset.bottom = contentInset.bottom
        }

        if scrollView.verticalScrollIndicatorInsets.bottom != indicatorBottomInset {
            scrollView.verticalScrollIndicatorInsets.bottom = indicatorBottomInset
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
