import UIKit

/// A view that is responsible for displaying an `Element` hierarchy.
///
/// A view controller that renders content via Blueprint might look something
/// like this:
///
/// ```
/// final class HelloWorldViewController: UIViewController {
///
///    private var blueprintView = BlueprintView(element: nil)
///
///    override func viewDidLoad() {
///        super.viewDidLoad()
///
///        let rootElement = Label(text: "Hello, world!")
///        blueprintView.element = rootElement
///        view.addSubview(blueprintView)
///     }
///
///     override func viewDidLayoutSubviews() {
///         super.viewDidLayoutSubviews()
///         blueprintView.frame = view.bounds
///     }
///
/// }
/// ```
public final class BlueprintView: UIView {

    private(set) var needsViewHierarchyUpdate: Bool = true
    private var hasUpdatedViewHierarchy: Bool = false
    private var lastViewHierarchyUpdateBounds: CGRect = .zero

    /// Used to detect reentrant updates
    private var isInsideUpdate: Bool = false

    private let rootController: NativeViewController

    private var sizesThatFit: [SizeConstraint: CGSize] = [:]

    /// A base environment used when laying out and rendering the element tree.
    ///
    /// Some keys will be overridden with the traits from the view itself. Eg, `windowSize`, `safeAreaInsets`, etc.
    ///
    /// If this blueprint view is within another blueprint view, the environment of the parent view
    /// will be inherited by this view if `automaticallyInheritsEnvironmentFromContainingBlueprintViews`
    /// is enabled. In the case of matching keys in both the inherited environment and the provided
    /// environment, the values from this environment will take priority over the inherited environment.
    public var environment: Environment {
        didSet {
            // Shortcut: If both environments were empty, nothing changed.
            if oldValue.isEmpty && environment.isEmpty { return }

            setNeedsViewHierarchyUpdate()
        }
    }

    ///
    /// If `true`, then Blueprint will automatically inherit the  ``Environment`` from the nearest
    /// parent ``BlueprintView`` in the view hierarchy.
    ///
    /// If `false`, then only the values from ``BlueprintView/environment`` will be used to
    /// seed the environment passed to the element hierarchy.
    ///
    /// This property is recursive – if the nearest parent ``BlueprintView`` also sets this property to
    /// true, then you will inherit the ``Environment`` from that view's parent ``BlueprintView``, and so on.
    ///
    /// Defaults to `true`.
    ///
    public var automaticallyInheritsEnvironmentFromContainingBlueprintViews: Bool = true {
        didSet {
            if oldValue == automaticallyInheritsEnvironmentFromContainingBlueprintViews {
                return
            }

            setNeedsViewHierarchyUpdate()
        }
    }

    /// The root element that is displayed within the view.
    public var element: Element? {
        didSet {
            // Minor performance optimization: We do not need to update anything if the element remains nil.
            if oldValue == nil && element == nil {
                return
            }

            Logger.logElementAssigned(view: self)

            setNeedsViewHierarchyUpdate()
        }
    }

    /// We need to invalidateIntrinsicContentSize when `bound.size` changes for Auto Layout to work correctly.
    public override var bounds: CGRect {
        didSet {
            guard oldValue.size != bounds.size else { return }

            invalidateIntrinsicContentSize()
        }
    }

    /// An optional name to help identify this view
    public var name: String?

    /// Provides performance metrics about the duration of layouts, updates, etc.
    public weak var metricsDelegate: BlueprintViewMetricsDelegate? = nil

    private var isVisible: Bool = false {
        didSet {
            switch (oldValue, isVisible) {
            case (false, true):
                handleAppeared()
            case (true, false):
                handleDisappeared()
            default: break
            }
        }
    }

    /// Instantiates a view with the given element
    ///
    /// - parameter element: The root element that will be displayed in the view.
    /// - parameter environment: A base environment to render elements with. Defaults to `.empty`.
    public required init(element: Element?, environment: Environment = .empty) {

        self.element = element
        self.environment = environment

        rootController = NativeViewController(
            node: NativeViewNode(
                content: UIView.describe { _ in },
                // Because no layout update occurs here, passing an empty environment is fine;
                // the correct environment will be passed during update.
                environment: .empty,
                layoutAttributes: LayoutAttributes(),
                children: []
            )
        )

        super.init(frame: CGRect.zero)

        backgroundColor = .white
        addSubview(rootController.view)
        setContentHuggingPriority(.defaultHigh, for: .horizontal)
        setContentHuggingPriority(.defaultHigh, for: .vertical)
    }

    public convenience override init(frame: CGRect) {
        self.init(element: nil)
        self.frame = frame
    }

    @available(*, unavailable)
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not available for BlueprintView.")
    }

    ///
    /// Measures the size needed to display the view within the given constraining size,
    /// by measuring the current `element` of the `BlueprintView`.
    ///
    /// If you would like to not constrain the measurement in a given axis,
    /// pass `0.0` or `.greatestFiniteMagnitude` for that axis, eg:
    ///
    /// ```
    /// // Measures with a width of 100, and no height constraint.
    /// blueprintView.sizeThatFits(CGSize(width: 100.0, height: 0.0))
    ///
    /// // Measures with a height of 100, and no width constraint.
    /// blueprintView.sizeThatFits(CGSize(width: 0.0, height: 100.0))
    ///
    /// // Measures unconstrained in both axes.
    /// blueprintView.sizeThatFits(.zero)
    /// ```
    ///
    public override func sizeThatFits(_ fittingSize: CGSize) -> CGSize {

        func measurementConstraint(with size: CGSize) -> SizeConstraint {

            let unconstrainedValues: Set<CGFloat> = [0.0, .greatestFiniteMagnitude, .infinity]

            let widthUnconstrained = unconstrainedValues.contains(size.width)
            let heightUnconstrained = unconstrainedValues.contains(size.height)

            return SizeConstraint(
                width: widthUnconstrained ? .unconstrained : .atMost(size.width),
                height: heightUnconstrained ? .unconstrained : .atMost(size.height)
            )
        }

        return sizeThatFits(measurementConstraint(with: fittingSize))
    }

    /// Measures the size needed to display the view within the given `SizeConstraint`.
    /// by measuring the current `element` of the `BlueprintView`.
    public func sizeThatFits(_ constraint: SizeConstraint) -> CGSize {
        guard let element = element else {
            return .zero
        }

        if let cachedSize = sizesThatFit[constraint] {
            return cachedSize
        }

        let measurement = element.content.measure(
            in: constraint,
            environment: makeEnvironment(),
            cache: CacheFactory.makeCache(name: "sizeThatFits:\(type(of: element))")
        )

        sizesThatFit[constraint] = measurement

        return measurement
    }

    ///
    /// Measures the size needed to display the view within then given constraining size,
    /// by measuring the current `element` of the `BlueprintView`.
    ///
    /// If you would like to not constrain the measurement in a given axis,
    /// pass `0.0` or `.greatestFiniteMagnitude` for that axis.
    ///
    public override func systemLayoutSizeFitting(
        _ targetSize: CGSize
    ) -> CGSize {
        /// For us, this is the same as `sizeThatFits`, since blueprint does not
        /// contain the same concept of constraints as Autolayout.
        sizeThatFits(targetSize)
    }

    ///
    /// Measures the size needed to display the view within then given constraining size,
    /// by measuring the current `element` of the `BlueprintView`.
    ///
    /// If you would like to not constrain the measurement in a given axis,
    /// pass `0.0` or `.greatestFiniteMagnitude` for that axis.
    ///
    public override func systemLayoutSizeFitting(
        _ targetSize: CGSize,
        withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
        verticalFittingPriority: UILayoutPriority
    ) -> CGSize {
        /// For us, this is the same as `sizeThatFits`, since blueprint does not
        /// contain the same concept of constraints as Autolayout.
        sizeThatFits(targetSize)
    }

    public override var intrinsicContentSize: CGSize {
        guard element != nil else {
            return CGSize(
                width: UIView.noIntrinsicMetric,
                height: UIView.noIntrinsicMetric
            )
        }

        func constraint() -> SizeConstraint {
            if bounds.width == 0 {
                return .unconstrained
            } else {
                return .init(width: bounds.width)
            }
        }

        return sizeThatFits(constraint())
    }

    public override var semanticContentAttribute: UISemanticContentAttribute {
        didSet {
            if semanticContentAttribute != oldValue {
                setNeedsViewHierarchyUpdate()
            }
        }
    }

    public override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()

        setNeedsViewHierarchyUpdate()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        updateViewHierarchyIfNeeded()
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        isVisible = (window != nil)
        setNeedsViewHierarchyUpdate()
    }

    /// Clears any sizing caches, invalidates the `intrinsicContentSize` of the
    /// view, and marks the view as needing a layout.
    private func setNeedsViewHierarchyUpdate() {

        invalidateIntrinsicContentSize()
        sizesThatFit.removeAll()

        if needsViewHierarchyUpdate { return }

        needsViewHierarchyUpdate = true

        /// We use `UIView`'s layout pass to actually perform a hierarchy update.
        /// If a manual update is required, call `layoutIfNeeded()`.
        setNeedsLayout()
    }

    private func updateViewHierarchyIfNeeded() {
        guard needsViewHierarchyUpdate || bounds != lastViewHierarchyUpdateBounds else { return }

        precondition(
            !isInsideUpdate,
            "Reentrant updates are not supported in BlueprintView. Ensure that view events from within the hierarchy are not synchronously triggering additional updates."
        )

        isInsideUpdate = true

        needsViewHierarchyUpdate = false
        lastViewHierarchyUpdateBounds = bounds

        let start = Date()
        Logger.logLayoutStart(view: self)

        let environment = makeEnvironment()

        /// Grab view descriptions
        let viewNodes = element?
            .layout(layoutAttributes: LayoutAttributes(frame: bounds), environment: environment)
            .resolve() ?? []

        let measurementEndDate = Date()
        Logger.logLayoutEnd(view: self)

        rootController.view.frame = bounds

        var rootNode = NativeViewNode(
            content: UIView.describe { _ in },
            environment: environment,
            layoutAttributes: LayoutAttributes(frame: bounds),
            children: viewNodes
        )

        let scale = window?.screen.scale ?? UIScreen.main.scale
        rootNode.round(from: .zero, correction: .zero, scale: scale)

        Logger.logViewUpdateStart(view: self)

        let updateResult = rootController.update(
            node: rootNode,
            context: .init(
                appearanceTransitionsEnabled: hasUpdatedViewHierarchy,
                viewIsVisible: isVisible
            )
        )

        for callback in updateResult.lifecycleCallbacks {
            callback()
        }

        Logger.logViewUpdateEnd(view: self)
        let viewUpdateEndDate = Date()

        hasUpdatedViewHierarchy = true

        isInsideUpdate = false

        metricsDelegate?.blueprintView(
            self,
            completedUpdateWith: .init(
                totalDuration: viewUpdateEndDate.timeIntervalSince(start),
                measureDuration: measurementEndDate.timeIntervalSince(start),
                viewUpdateDuration: viewUpdateEndDate.timeIntervalSince(measurementEndDate)
            )
        )
    }

    var currentNativeViewControllers: [(path: ElementPath, node: NativeViewController)] {

        /// Perform an update if needed so that the node hierarchy is fully populated.
        updateViewHierarchyIfNeeded()

        /// rootViewNode always contains a simple UIView – its children represent the
        /// views that are actually generated by the root element.
        return rootController.children
    }

    private func makeEnvironment() -> Environment {

        let inherited: Environment = {
            if
                self.automaticallyInheritsEnvironmentFromContainingBlueprintViews,
                let inherited = self.inheritedBlueprintEnvironment
            {
                return inherited
            } else {
                return .empty
            }
        }()

        var environment = inherited.merged(prioritizing: self.environment)

        if let displayScale = window?.screen.scale {
            environment.displayScale = displayScale
        }

        let layoutDirection = UIView.userInterfaceLayoutDirection(for: semanticContentAttribute)
        environment.layoutDirection = Environment.LayoutDirection(layoutDirection)

        environment.safeAreaInsets = safeAreaInsets

        if let window = window {
            environment.windowSize = window.bounds.size
        }

        return environment
    }

    private func handleAppeared() {
        rootController.traverse { node in
            node.onAppear?()
        }
    }

    private func handleDisappeared() {
        rootController.traverse { node in
            node.onDisappear?()
        }
    }
}


/// Provides performance information for blueprint measurements and updates.
public protocol BlueprintViewMetricsDelegate: AnyObject {

    func blueprintView(_ view: BlueprintView, completedUpdateWith metrics: BlueprintViewUpdateMetrics)

}


public struct BlueprintViewUpdateMetrics {

    /// The total time it took to apply a new element.
    public var totalDuration: TimeInterval
    /// The time it took to lay out and measure the new element.
    public var measureDuration: TimeInterval
    /// The time it took to update the on-screen views for the element.
    public var viewUpdateDuration: TimeInterval
}


extension BlueprintView {

    final class NativeViewController {

        private var viewDescription: ViewDescription
        private var layoutAttributes: LayoutAttributes

        private(set) var children: [(ElementPath, NativeViewController)]

        var onAppear: LifecycleCallback? {
            viewDescription.onAppear
        }

        var onDisappear: LifecycleCallback? {
            viewDescription.onDisappear
        }

        let view: UIView

        init(node: NativeViewNode) {
            viewDescription = node.viewDescription
            layoutAttributes = node.layoutAttributes
            children = []

            view = node.viewDescription.build()
            view.nativeViewNodeBlueprintEnvironment = node.environment
        }

        deinit {
            self.view.nativeViewNodeBlueprintEnvironment = nil
        }

        fileprivate func canUpdateFrom(node: NativeViewNode) -> Bool {
            node.viewDescription.viewType == type(of: view)
        }

        fileprivate func update(node: NativeViewNode, context: UpdateContext) -> UpdateResult {

            assert(node.viewDescription.viewType == type(of: view))

            viewDescription = node.viewDescription
            layoutAttributes = node.layoutAttributes

            view.nativeViewNodeBlueprintEnvironment = node.environment

            viewDescription.apply(to: view)

            // After this view's children are updated, allow it to run a layout pass.
            // This ensures backing view layout changes are contained in animation blocks.
            defer {
                view.layoutIfNeeded()
            }

            var result = UpdateResult()

            // Bail out fast if we do not have any children to manage.
            // This is a performance optimization for leaf elements, as the below update
            // pass is otherwise expensive to perform for empty elements.
            if children.isEmpty && node.children.isEmpty {
                return result
            }

            var oldChildren: [ElementPath: NativeViewController] = [:]
            oldChildren.reserveCapacity(children.count)

            let oldPaths: [ElementPath] = children.map { $0.0 }

            for (path, childController) in children {
                oldChildren[path] = childController
            }

            var newChildren: [(path: ElementPath, node: NativeViewController)] = []
            newChildren.reserveCapacity(node.children.count)

            let newPaths: [ElementPath] = node.children.map { $0.path }

            var usedKeys: Set<ElementPath> = []
            usedKeys.reserveCapacity(node.children.count)

            let pathsChanged = oldPaths != newPaths

            for index in node.children.indices {
                let (path, child) = node.children[index]

                guard usedKeys.contains(path) == false else {
                    fatalError("Duplicate view identifier")
                }
                usedKeys.insert(path)

                let contentView = node.viewDescription.contentView(in: view)

                if let controller = oldChildren[path], controller.canUpdateFrom(node: child) {

                    oldChildren.removeValue(forKey: path)
                    newChildren.append((path: path, node: controller))

                    let layoutTransition: LayoutTransition

                    if child.layoutAttributes != controller.layoutAttributes {
                        layoutTransition = child.viewDescription.layoutTransition
                    } else {
                        layoutTransition = .inherited
                    }
                    layoutTransition.perform {
                        child.layoutAttributes.apply(to: controller.view)

                        if pathsChanged {
                            // Only update the index of the view if the content of the parent view changed.
                            // This is a performance optimization, as this call is otherwise expensive if the index of the
                            // view did not change (it leads to the `contentView` having to check the index of the subview for no reason).
                            contentView.insertSubview(controller.view, at: index)
                        }

                        let childResult = controller.update(node: child, context: context)
                        result.merge(childResult)
                    }
                } else {
                    var controller: NativeViewController!

                    // Building the view and applying the initial layout and update need to be wrapped in
                    // performWithoutAnimation so they're not caught up inside an occuring transition.
                    UIView.performWithoutAnimation {
                        controller = NativeViewController(node: child)
                        child.layoutAttributes.apply(to: controller.view)

                        contentView.insertSubview(controller.view, at: index)

                        if context.viewIsVisible, let onAppear = controller.onAppear {
                            result.lifecycleCallbacks.append(onAppear)
                        }

                        let childResult = controller.update(
                            node: child,
                            context: context.modified {
                                $0.appearanceTransitionsEnabled = false
                            }
                        )
                        result.merge(childResult)
                    }

                    newChildren.append((path: path, node: controller))

                    if context.appearanceTransitionsEnabled {
                        child.viewDescription.appearingTransition?.performAppearing(
                            view: controller.view,
                            layoutAttributes: child.layoutAttributes,
                            completion: {}
                        )
                    }
                }
            }

            for controller in oldChildren.values {
                func removeChild() {
                    controller.view.removeFromSuperview()
                }

                if context.viewIsVisible {
                    controller.traverse { node in
                        if let onDisappear = node.onDisappear {
                            result.lifecycleCallbacks.append(onDisappear)
                        }
                    }
                }

                if let transition = controller.viewDescription.disappearingTransition {
                    transition.performDisappearing(
                        view: controller.view,
                        layoutAttributes: controller.layoutAttributes,
                        completion: removeChild
                    )
                } else {
                    removeChild()
                }
            }

            children = newChildren

            return result
        }

        /// Perform a depth-first traversal of the view-backing tree from this node.
        func traverse(visitor: (NativeViewController) -> Void) {
            visitor(self)
            for (_, child) in children {
                child.traverse(visitor: visitor)
            }
        }
    }
}

extension BlueprintView.NativeViewController {

    /// A context value passed to the ``BlueprintView/NativeViewController`` instance as the view tree is updated by blueprint.
    /// Contains information relevant to the correct construction and management of the view tree.
    struct UpdateContext {

        /// If appearance transitions are enabled for insertions and removals.
        var appearanceTransitionsEnabled: Bool

        /// True if the hosting view is in the view hierarchy
        var viewIsVisible: Bool

        /// Returns a copy of the update context, modified by the changes provided.
        func modified(_ modify: (inout Self) -> Void) -> Self {
            var modified = self
            modify(&modified)
            return modified
        }
    }

    /// The result of a native view update, including all child updates.
    struct UpdateResult {
        /// The lifecycle callbacks accumulated during the view update.
        var lifecycleCallbacks: [LifecycleCallback] = []

        /// Merges another update result (such as from a child) into this result.
        mutating func merge(_ other: UpdateResult) {
            lifecycleCallbacks += other.lifecycleCallbacks
        }
    }
}

