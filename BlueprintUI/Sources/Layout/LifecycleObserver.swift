
/// Allows element lifecycle callbacks to be inserted anywhere into the element tree.
///
public struct LifecycleObserver: Element {
    public var wrapped: Element

    public var onAppear: LifecycleCallback?
    public var onDisappear: LifecycleCallback?

    public init(
        onAppear: LifecycleCallback? = nil,
        onDisappear: LifecycleCallback? = nil,
        wrapping: Element
    ) {
        self.onAppear = onAppear
        self.onDisappear = onDisappear
        wrapped = wrapping
    }

    public var content: ElementContent {
        ElementContent(child: wrapped)
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        PassthroughView.describe { config in
            config.onAppear = onAppear
            config.onDisappear = onDisappear
        }
    }
}

// These extensions collapse chained callbacks into a single element
extension LifecycleObserver {
    /// Adds a hook that will be called when this element appears.
    ///
    /// Callbacks run in depth-first traversal order, with parents before children.
    public func onAppear(_ callback: @escaping LifecycleCallback) -> LifecycleObserver {
        LifecycleObserver(
            onAppear: onAppear + callback,
            onDisappear: onDisappear,
            wrapping: wrapped
        )
    }

    /// Adds a hook that will be called when this element disappears.
    ///
    /// Callbacks run in depth-first traversal order, with parents before children. There is no
    /// guaranteed order between disappearance callbacks and backing views being removed from their
    /// superviews.
    public func onDisappear(_ callback: @escaping LifecycleCallback) -> LifecycleObserver {
        LifecycleObserver(
            onAppear: onAppear,
            onDisappear: onDisappear + callback,
            wrapping: wrapped
        )
    }
}

extension Element {
    /// Adds a hook that will be called when this element appears.
    ///
    /// Callbacks run in depth-first traversal order, with parents before children.
    public func onAppear(_ callback: @escaping LifecycleCallback) -> LifecycleObserver {
        LifecycleObserver(onAppear: callback, wrapping: self)
    }

    /// Adds a hook that will be called when this element disappears.
    ///
    /// Callbacks run in depth-first traversal order, with parents before children. There is no
    /// guaranteed order between disappearance callbacks and backing views being removed from their
    /// superviews.
    public func onDisappear(_ callback: @escaping LifecycleCallback) -> LifecycleObserver {
        LifecycleObserver(onDisappear: callback, wrapping: self)
    }
}

/// Concatenate callbacks.
private func + (lhs: LifecycleCallback?, rhs: @escaping LifecycleCallback) -> LifecycleCallback {
    if let lhs = lhs {
        return {
            lhs()
            rhs()
        }
    }
    return rhs
}
