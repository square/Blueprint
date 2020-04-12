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
    public var keyboardAdjustmentMode : KeyboardAdjustmentMode = .adjustsWhenVisible

    public init(wrapping element: Element, configure : (inout ScrollView) -> () = { _ in }) {
        self.wrappedElement = element
        configure(&self)
    }

    public var content: ElementContent {
        return ElementContent(
            child: wrappedElement,
            layout: Layout(
                contentInset: contentInset,
                contentSize: contentSize,
                centersUnderflow: centersUnderflow
            )
        )
    }

    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return ScrollerWrapperView.describe { config in
            config.builder = {
                ScrollerWrapperView(frame: bounds, representedElement: self)
            }
            
            config.contentView = { $0.scrollView }
            
            config.apply {
                $0.apply(scrollView: self, contentFrame: subtreeExtent ?? .zero)
            }
        }
    }
}

extension ScrollView {

    fileprivate struct Layout: SingleChildLayout {

        var contentInset: UIEdgeInsets
        var contentSize: ContentSize
        var centersUnderflow: Bool
        
        func layout(in constraint: SizeConstraint, child: MeasurableChild) -> SingleChildLayoutResult {
            SingleChildLayoutResult(
                size: {
                    let adjustedConstraint = constraint.inset(
                        width: contentInset.left + contentInset.right,
                        height: contentInset.top + contentInset.bottom
                    )

                    var result = self.fittedSize(in: adjustedConstraint, childSize: { child.size(in: $0) })

                    result.width += contentInset.left + contentInset.right
                    result.height += contentInset.top + contentInset.bottom

                    result.width = min(result.width, constraint.width.maximum)
                    result.height = min(result.height, constraint.height.maximum)

                    return result
                },
                layoutAttributes: { size in
                    var insetSize = size
                    insetSize.width -= contentInset.left + contentInset.right
                    insetSize.height -= contentInset.top + contentInset.bottom

                    var itemSize = fittedSize(in: SizeConstraint(insetSize), childSize: { child.size(in: $0) })
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
            )
        }

        private func fittedSize(in constraint: SizeConstraint, childSize : (SizeConstraint) -> CGSize) -> CGSize {
            switch contentSize {
            case .custom(let size):
                return size

            case .fittingContent:
                return childSize(.unconstrained)

            case .fittingHeight:
                return childSize(SizeConstraint(
                        width: constraint.width,
                        height: .unconstrained
                    )
                )

            case .fittingWidth:
                return childSize(SizeConstraint(
                        width: .unconstrained,
                        height: constraint.height
                    )
                )
            }
        }
    }

}

extension ScrollView {
    
    public enum KeyboardAdjustmentMode : Equatable {
        case none
        case adjustsWhenVisible
    }

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
    let keyboardObserver = KeyboardObserver()
    
    /// The current `ScrollView` state we represent.
    private var representedElement : ScrollView

    private var refreshControl: UIRefreshControl? = nil {

        didSet {
            scrollView.refreshControl = refreshControl
        }

    }

    private var refreshAction: () -> Void = { }

    init(frame: CGRect, representedElement : ScrollView) {
        
        self.representedElement = representedElement
        
        super.init(frame: frame)
        
        self.keyboardObserver.delegate = self
        
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

        self.representedElement = scrollView
        
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
        
        self.applyContentInset(with: scrollView)
    }
    
    private func applyContentInset(with scrollView : ScrollView)
    {
        let contentInset = ScrollView.calculateContentInset(
            scrollViewInsets: scrollView.contentInset,
            safeAreaInsets: self.bp_safeAreaInsets,
            keyboardBottomInset: self.bottomContentInsetAdjustmentForKeyboard,
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
        
        if self.window != nil {
            self.updateBottomContentInsetWithKeyboardFrame()
        }
    }
    
    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        if self.superview != nil {
            self.updateBottomContentInsetWithKeyboardFrame()
        }
    }
}


extension ScrollView
{
    // Calculates the correct content inset to apply for the given inputs.
    
    static func calculateContentInset(
        scrollViewInsets : UIEdgeInsets,
        safeAreaInsets : UIEdgeInsets,
        keyboardBottomInset : CGFloat,
        refreshControlState : PullToRefreshBehavior,
        refreshControlBounds : CGRect?
    ) -> UIEdgeInsets
    {
        var finalContentInset = scrollViewInsets
        
        // Include the keyboard's adjustment at the bottom of the scroll view.
        
        if keyboardBottomInset > 0.0 {
            finalContentInset.bottom += keyboardBottomInset
            
            // Exclude the safe area insets, so the content hugs the top of the keyboard.
            
            finalContentInset.bottom -= safeAreaInsets.bottom
        }
        
        // The refresh control lives above the content and adjusts the
        // content inset for itself when visible and refreshing.
        // Do the same adjustment to our expected content inset.
        
        if case .refreshing = refreshControlState {
            finalContentInset.top += refreshControlBounds?.size.height ?? 0.0
        }
        
        return finalContentInset
    }
}


extension ScrollerWrapperView : KeyboardObserverDelegate {
    
    //
    // MARK: Keyboard
    //
    
    private func updateBottomContentInsetWithKeyboardFrame() {
        
        let contentInset = ScrollView.calculateContentInset(
            scrollViewInsets: self.representedElement.contentInset,
            safeAreaInsets: self.bp_safeAreaInsets,
            keyboardBottomInset: self.bottomContentInsetAdjustmentForKeyboard,
            refreshControlState: self.representedElement.pullToRefreshBehavior,
            refreshControlBounds: self.refreshControl?.bounds
        )
        
        /// Setting contentInset, even to the same value, can cause issues during scrolling (such as stopping scrolling).
        /// Make sure we're only assigning the value if it changed.
        
        if self.scrollView.contentInset.bottom != contentInset.bottom {
            self.scrollView.contentInset.bottom = contentInset.bottom
        }
    }
    
    fileprivate var bottomContentInsetAdjustmentForKeyboard : CGFloat {
        
        switch self.representedElement.keyboardAdjustmentMode {
        case .none:
            return 0.0
            
        case .adjustsWhenVisible:
            guard let keyboardFrame = self.keyboardObserver.currentFrame(in: self) else {
                return 0.0
            }
            
            switch keyboardFrame {
            case .nonOverlapping: return 0.0
            case .overlapping(let frame): return self.bounds.size.height - frame.origin.y
            }
        }
    }
    
    //
    // MARK: KeyboardObserverDelegate
    //
    
    func keyboardFrameWillChange(
        for observer : KeyboardObserver,
        animationDuration : Double,
        options : UIView.AnimationOptions
    ) {
        UIView.animate(withDuration: animationDuration, delay: 0.0, options: options, animations: {
            self.updateBottomContentInsetWithKeyboardFrame()
        })
    }
}


private extension UIView {
    
    var bp_safeAreaInsets : UIEdgeInsets {
        if #available(iOS 11.0, *) {
            return self.safeAreaInsets
        } else {
            return .zero
        }
    }
}
