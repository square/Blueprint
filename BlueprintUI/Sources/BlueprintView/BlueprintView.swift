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

    /// The controller which manages updates for the root node in the element tree.
    private let rootController: NativeViewController
    
    /// A cache passed to elements which they can use to request a prototype view for measuring
    /// their contents. See ``LayoutContext/measure(_:using:measure:)`` for more.
    private let measurementViews : LayoutContext.MeasurementViews = .init()
    
    /// The live, tracked state for each element in the element tree.
    private let rootState : ElementState?

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
            setNeedsViewHierarchyUpdate()
            invalidateIntrinsicContentSize()
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
    public var automaticallyInheritsEnvironmentFromContainingBlueprintViews : Bool = true {
        didSet {
            setNeedsViewHierarchyUpdate()
            invalidateIntrinsicContentSize()
        }
    }

    /// The root element that is displayed within the view.
    public var element: Element? {
        didSet {
            // Minor performance optimization: We do not need to update anything if the element remains nil.
            if oldValue == nil && self.element == nil {
                return
            }

            Logger.logElementAssigned(view: self)
            
            setNeedsViewHierarchyUpdate()
            invalidateIntrinsicContentSize()
        }
    }

    /// An optional name to help identify this view
    public var name: String?
    
    /// Provides performance metrics about the duration of layouts, updates, etc.
    public weak var metricsDelegate : BlueprintViewMetricsDelegate? = nil

    /// Instantiates a view with the given element
    ///
    /// - parameter element: The root element that will be displayed in the view.
    /// - parameter environment: A base environment to render elements with. Defaults to `.empty`.
    public required init(element: Element?, environment: Environment = .empty) {

        self.element = element
        self.environment = environment
        
        rootController = NativeViewController(
            node: NativeViewNode(
                content: UIView.describe() { _ in },
                // Because no layout update occurs here, passing an empty environment is fine;
                // the correct environment will be passed during update.
                environment: .empty,
                layoutAttributes: LayoutAttributes(),
                children: []
            )
        )
        
        self.rootState = nil
    
        super.init(frame: CGRect.zero)
        
        self.backgroundColor = .white
        addSubview(rootController.view)
        setContentHuggingPriority(.defaultHigh, for: .horizontal)
        setContentHuggingPriority(.defaultHigh, for: .vertical)
    }

    public override convenience init(frame: CGRect) {
        self.init(element: nil)
        self.frame = frame
    }

    @available(*, unavailable)
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    ///
    /// Measures the size needed to display the view within then given constraining size,
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
    override public func sizeThatFits(_ size: CGSize) -> CGSize {
        guard let element = element else {
            return .zero
        }
        
        func measurementConstraint(with size : CGSize) -> SizeConstraint {
            
            let unconstrainedValues : [CGFloat] = [0.0, .greatestFiniteMagnitude, .infinity]
            
            let widthUnconstrained = unconstrainedValues.contains(size.width)
            let heightUnconstrained = unconstrainedValues.contains(size.height)
            
            return SizeConstraint(
                width: widthUnconstrained ? .unconstrained : .atMost(size.width),
                height: heightUnconstrained ? .unconstrained : .atMost(size.height)
            )
        }
        
        return element.content.measure(
            in: measurementConstraint(with: size),
            with: .init(
                environment: self.makeEnvironment(),
                measurementCache: .init(),
                measurementViews: self.measurementViews
            ),
            cache: CacheFactory.makeCache(name: "sizeThatFits:\(type(of: element))")
        )
    }

    /// Returns the size of the element bound to the current width (mimicking
    /// UILabel’s `intrinsicContentSize` behavior)
    public override var intrinsicContentSize: CGSize {
        
        guard let element = element else { return .zero }
        
        let constraint: SizeConstraint

        // Use unconstrained when
        // a) we need a view hierarchy update to force a loop through an
        //    unconstrained width so we don’t end up “caching” the previous
        //    element’s width
        // b) the current width is zero, since constraining by zero is
        //    nonsensical
        if bounds.width == 0 || needsViewHierarchyUpdate {
            constraint = .unconstrained
        } else {
            constraint = SizeConstraint(width: bounds.width)
        }
        
        return element.content.measure(
            in: constraint,
            with: .init(
                environment: self.makeEnvironment(),
                measurementCache: .init(),
                measurementViews: self.measurementViews
            ),
            cache: CacheFactory.makeCache(name: "intrinsicContentSize:\(type(of: element))")
        )
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
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        invalidateIntrinsicContentSize()
        performUpdate()
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        setNeedsViewHierarchyUpdate()
    }
    
    private func performUpdate() {
        updateViewHierarchyIfNeeded()
    }
    
    private func setNeedsViewHierarchyUpdate() {
        guard !needsViewHierarchyUpdate else { return }
        needsViewHierarchyUpdate = true
        
        /// We currently rely on CA's layout pass to actually perform a hierarchy update.
        setNeedsLayout()
    }
    
    private func updateViewHierarchyIfNeeded() {
        guard needsViewHierarchyUpdate || bounds != lastViewHierarchyUpdateBounds else { return }

        assert(!isInsideUpdate, "Reentrant updates are not supported in BlueprintView. Ensure that view events from within the hierarchy are not synchronously triggering additional updates.")
        isInsideUpdate = true

        needsViewHierarchyUpdate = false
        lastViewHierarchyUpdateBounds = bounds
        
        let start = Date()
        Logger.logLayoutStart(view: self)
        
        let environment = self.makeEnvironment()

        /// Grab view descriptions
        let viewNodes = self.calculateNativeViewNodes(in: environment)
        
        let measurementEndDate = Date()
        Logger.logLayoutEnd(view: self)

        rootController.view.frame = bounds
        
        var rootNode = NativeViewNode(
            content: UIView.describe() { _ in },
            environment: environment,
            layoutAttributes: LayoutAttributes(frame: bounds),
            children: viewNodes
        )

        let scale = window?.screen.scale ?? UIScreen.main.scale
        rootNode.round(from: .zero, correction: .zero, scale: scale)

        Logger.logViewUpdateStart(view: self)

        rootController.update(
            node: rootNode,
            context: .init(
                appearanceTransitionsEnabled: hasUpdatedViewHierarchy
            )
        )

        Logger.logViewUpdateEnd(view: self)
        let viewUpdateEndDate = Date()
        
        hasUpdatedViewHierarchy = true

        isInsideUpdate = false
        
        self.metricsDelegate?.blueprintView(
            self,
            completedUpdateWith: .init(
                totalDuration: viewUpdateEndDate.timeIntervalSince(start),
                measureDuration: measurementEndDate.timeIntervalSince(start),
                viewUpdateDuration: viewUpdateEndDate.timeIntervalSince(measurementEndDate)
            )
        )
    }
    
    /// Performs a full measurement and layout pass of all contained elements, and then collapses the nodes down
    /// into `NativeViewNode`s, which represent only the view-backed elements. These view nodes
    /// are then pushed into a `NativeViewController` to update the on-screen view hierarchy.
    private func calculateNativeViewNodes(in environment : Environment, states : ElementState) -> [(path: ElementPath, node: NativeViewNode)] {
        guard let element = self.element else { return [] }
        
        let laidOutNodes = LayoutResultNode(
            root: element,
            layoutAttributes: .init(frame: self.bounds),
            environment: environment,
            measurementViews: self.measurementViews
        )
        
        return laidOutNodes.resolve()
    }

    var currentNativeViewControllers: [(path: ElementPath, node: NativeViewController)] {

        /// Perform an update if needed so that the node hierarchy is fully populated.
        updateViewHierarchyIfNeeded()

        /// rootViewNode always contains a simple UIView – its children represent the
        /// views that are actually generated by the root element.
        return rootController.children
    }
    
    private func makeEnvironment() -> Environment {
                
        let inherited : Environment = {
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
}


/// Provides performance information for blueprint measurements and updates.
public protocol BlueprintViewMetricsDelegate : AnyObject {
    
    func blueprintView(_ view : BlueprintView, completedUpdateWith metrics : BlueprintViewUpdateMetrics)
    
}


public struct BlueprintViewUpdateMetrics {
    
    /// The total time it took to apply a new element.
    public var totalDuration : TimeInterval
    /// The time it took to lay out and measure the new element.
    public var measureDuration : TimeInterval
    /// The time it took to update the on-screen views for the element.
    public var viewUpdateDuration : TimeInterval
}


extension BlueprintView {
    
    final class NativeViewController {

        private var viewDescription: ViewDescription
        private var layoutAttributes: LayoutAttributes
        
        private (set) var children: [(ElementPath, NativeViewController)]
        
        let view: UIView
        
        init(node: NativeViewNode) {
            self.viewDescription = node.viewDescription
            self.layoutAttributes = node.layoutAttributes
            self.children = []
            
            self.view = node.viewDescription.build()
            self.view.nativeViewNodeBlueprintEnvironment = node.environment
        }
        
        deinit {
            self.view.nativeViewNodeBlueprintEnvironment = nil
        }

        fileprivate func canUpdateFrom(node: NativeViewNode) -> Bool {
            return node.viewDescription.viewType == type(of: view)
        }
        
        fileprivate func update(node: NativeViewNode, context : UpdateContext) {
                        
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
            
            // Bail out fast if we do not have any children to manage.
            // This is a performance optimization for leaf elements, as the below update
            // pass is otherwise expensive to perform for empty elements.
            if self.children.isEmpty && node.children.isEmpty {
                return
            }
            
            var oldChildren: [ElementPath: NativeViewController] = [:]
            oldChildren.reserveCapacity(children.count)
            
            let oldPaths : [ElementPath] = children.map { $0.0 }
            
            for (path, childController) in children {
                oldChildren[path] = childController
            }
            
            var newChildren: [(path: ElementPath, node: NativeViewController)] = []
            newChildren.reserveCapacity(node.children.count)
            
            let newPaths : [ElementPath] = node.children.map { $0.path }
            
            var usedKeys: Set<ElementPath> = []
            usedKeys.reserveCapacity(node.children.count)
            
            let pathsChanged = oldPaths != newPaths
            
            for index in node.children.indices {
                let (path, child) = node.children[index]

                guard usedKeys.contains(path) == false else {
                    fatalError("Duplicate view identifier")
                }
                usedKeys.insert(path)

                let contentView = node.viewDescription.contentView(in: self.view)

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

                        controller.update(node: child, context: context)
                    }
                } else {
                    var controller: NativeViewController!

                    // Building the view and applying the initial layout and update need to be wrapped in
                    // performWithoutAnimation so they're not caught up inside an occuring transition.
                    UIView.performWithoutAnimation {
                        controller = NativeViewController(node: child)
                        child.layoutAttributes.apply(to: controller.view)

                        contentView.insertSubview(controller.view, at: index)

                        controller.update(node: child, context: context.modified {
                            $0.appearanceTransitionsEnabled = false
                        })
                    }

                    newChildren.append((path: path, node: controller))

                    if context.appearanceTransitionsEnabled {
                        child.viewDescription.appearingTransition?.performAppearing(view: controller.view, layoutAttributes: child.layoutAttributes, completion: {})
                    }
                }
            }
            
            for controller in oldChildren.values {
                if let transition = controller.viewDescription.disappearingTransition {
                    transition.performDisappearing(view: controller.view, layoutAttributes: controller.layoutAttributes, completion: {
                        controller.view.removeFromSuperview()
                    })
                } else {
                    controller.view.removeFromSuperview()
                }
            }
            
            children = newChildren
        }
    }
}

extension BlueprintView.NativeViewController {
    
    /// A context value passed to the ``BlueprintView/NativeViewController`` instance as the view tree is updated by blueprint.
    /// Contains information relevant to the correct construction and management of the view tree.
    struct UpdateContext {
        
        /// If appearance transitions are enabled for insertions and removals.
        var appearanceTransitionsEnabled : Bool
        
        /// Returns a copy of the update context, modified by the changes provided.
        func modified(_ modify: (inout Self) -> ()) -> Self {
            var modified = self
            modify(&modified)
            return modified
        }
    }
}
