import BlueprintUI

/// Allows element lifecycle callbacks to be inserted anywhere into the element tree.
///
/// For more details about lifecycle hooks, see `LifecycleCallback`.
///
/// ## In Xcode
/// [The Element Lifecycle](x-source-tag://ElementLifecycle)
///
public struct LifecycleObserver: Element {
    public var wrapped: Element

    public var onAppear: LifecycleCallback?
    public var onDisappear: LifecycleCallback?

    public var onMount: LifecycleCallback?
    public var onUnmount: LifecycleCallback?

    public init(
        onAppear: LifecycleCallback? = nil,
        onDisappear: LifecycleCallback? = nil,
        onMount: LifecycleCallback? = nil,
        onUnmount: LifecycleCallback? = nil,
        wrapping: Element
    ) {
        self.onAppear = onAppear
        self.onDisappear = onDisappear
        self.onMount = onMount
        self.onUnmount = onUnmount
        wrapped = wrapping
    }

    public var content: ElementContent {
        ElementContent(child: wrapped)
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        PassthroughView.describe { config in
            config.onAppear = onAppear
            config.onDisappear = onDisappear
            config.onMount = onMount
            config.onUnmount = onUnmount
        }
    }
}

// These extensions collapse chained callbacks into a single element
extension LifecycleObserver {
    /// Adds a hook that will be called when this element appears.
    ///
    /// For more details about lifecycle hooks, see `LifecycleCallback`.
    ///
    /// ## In Xcode
    /// [The Element Lifecycle](x-source-tag://ElementLifecycle)
    ///
    public func onAppear(_ callback: @escaping LifecycleCallback) -> LifecycleObserver {
        LifecycleObserver(
            onAppear: onAppear + callback,
            onDisappear: onDisappear,
            onMount: onMount,
            onUnmount: onUnmount,
            wrapping: wrapped
        )
    }

    /// Adds a hook that will be called when this element disappears.
    ///
    /// For more details about lifecycle hooks, see `LifecycleCallback`.
    ///
    /// ## In Xcode
    /// [The Element Lifecycle](x-source-tag://ElementLifecycle)
    ///
    public func onDisappear(_ callback: @escaping LifecycleCallback) -> LifecycleObserver {
        LifecycleObserver(
            onAppear: onAppear,
            onDisappear: onDisappear + callback,
            onMount: onMount,
            onUnmount: onUnmount,
            wrapping: wrapped
        )
    }

    /// Adds a hook that will be called when this element is mounted.
    ///
    /// For more details about lifecycle hooks, see `LifecycleCallback`.
    ///
    /// ## In Xcode
    /// [The Element Lifecycle](x-source-tag://ElementLifecycle)
    ///
    public func onMount(_ callback: @escaping LifecycleCallback) -> LifecycleObserver {
        LifecycleObserver(
            onAppear: onAppear,
            onDisappear: onDisappear,
            onMount: onMount + callback,
            onUnmount: onUnmount,
            wrapping: wrapped
        )
    }

    /// Adds a hook that will be called when this element is unmounted.
    ///
    /// For more details about lifecycle hooks, see `LifecycleCallback`.
    ///
    /// ## In Xcode
    /// [The Element Lifecycle](x-source-tag://ElementLifecycle)
    ///
    public func onUnmount(_ callback: @escaping LifecycleCallback) -> LifecycleObserver {
        LifecycleObserver(
            onAppear: onAppear,
            onDisappear: onDisappear,
            onMount: onMount,
            onUnmount: onUnmount + callback,
            wrapping: wrapped
        )
    }
}

extension Element {
    /// Adds a hook that will be called when this element appears.
    ///
    /// For more details about lifecycle hooks, see `LifecycleCallback`.
    ///
    /// ## In Xcode
    /// [The Element Lifecycle](x-source-tag://ElementLifecycle)
    ///
    public func onAppear(_ callback: @escaping LifecycleCallback) -> LifecycleObserver {
        LifecycleObserver(onAppear: callback, wrapping: self)
    }

    /// Adds a hook that will be called when this element disappears.
    ///
    /// For more details about lifecycle hooks, see `LifecycleCallback`.
    ///
    /// ## In Xcode
    /// [The Element Lifecycle](x-source-tag://ElementLifecycle)
    ///
    public func onDisappear(_ callback: @escaping LifecycleCallback) -> LifecycleObserver {
        LifecycleObserver(onDisappear: callback, wrapping: self)
    }

    /// Adds a hook that will be called when this element is mounted.
    ///
    /// For more details about lifecycle hooks, see `LifecycleCallback`.
    ///
    /// ## In Xcode
    /// [The Element Lifecycle](x-source-tag://ElementLifecycle)
    ///
    public func onMount(_ callback: @escaping LifecycleCallback) -> LifecycleObserver {
        LifecycleObserver(onMount: callback, wrapping: self)
    }

    /// Adds a hook that will be called when this element is unmounted.
    ///
    /// For more details about lifecycle hooks, see `LifecycleCallback`.
    ///
    /// ## In Xcode
    /// [The Element Lifecycle](x-source-tag://ElementLifecycle)
    ///
    public func onUnmount(_ callback: @escaping LifecycleCallback) -> LifecycleObserver {
        LifecycleObserver(onUnmount: callback, wrapping: self)
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
