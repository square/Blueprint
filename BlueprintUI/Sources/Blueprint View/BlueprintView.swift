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

    private var needsViewHierarchyUpdate: Bool = true
    private var nextViewHierarchyUpdateEnablesAppearanceTransitions: Bool = false
    
    private var lastViewHierarchyUpdateBounds: CGRect = .zero

    /// Used to detect reentrant updates
    private var isInsideUpdate: Bool = false

    private let rootController: NativeViewController
    
    /// The root element that is displayed within the view.
    public var element: Element? {
        set {
            self.set(element: newValue)
        }
        get {
            return self._element
        }
    }
    
    public var viewController : UIViewController? = nil
    
    private var _element : Element?
    
    public func set(animated : Bool = UIView.isInAnimationBlock, element: Element?)
    {
        _element = element
        
        self.nextViewHierarchyUpdateEnablesAppearanceTransitions = animated
        
        self.setNeedsViewHierarchyUpdate()
    }

    /// Instantiates a view with the given element
    ///
    /// - parameter element: The root element that will be displayed in the view.
    public required init(element: Element?, animated: Bool = UIView.isInAnimationBlock) {
        
        _element = element
        
        self.nextViewHierarchyUpdateEnablesAppearanceTransitions = animated
        
        rootController = NativeViewController(
            node: NativeViewNode(
                content: UIView.describe() { _ in },
                layoutAttributes: LayoutAttributes(),
                children: []
            ),
            animated: animated
        )
    
        super.init(frame: CGRect.zero)
        
        self.backgroundColor = .white
        addSubview(rootController.view)
    }

    public override convenience init(frame: CGRect) {
        self.init(element: nil)
        self.frame = frame
    }

    @available(*, unavailable)
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Forwarded to the `measure(in:)` implementation of the root element.
    override public func sizeThatFits(_ size: CGSize) -> CGSize {
        guard let element = element else { return .zero }
        let constraint: SizeConstraint
        if size == .zero {
            constraint = SizeConstraint(width: .unconstrained, height: .unconstrained)
        } else {
            constraint = SizeConstraint(size)
        }
        return element.content.measure(in: constraint)
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        performUpdate()
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
        
        guard isInsideUpdate == false else {
            fatalError("Reentrant updates are not supported in BlueprintView. Ensure that view events from within the hierarchy are not synchronously triggering additional updates.")
        }

        isInsideUpdate = true
        needsViewHierarchyUpdate = false
        lastViewHierarchyUpdateBounds = bounds
        
        /// Grab view descriptions
        let viewNodes = element?
            .layout(frame: bounds)
            .resolve() ?? []
        
        rootController.view.frame = bounds
        
        let rootNode = NativeViewNode(
            content: UIView.describe() { _ in },
            layoutAttributes: LayoutAttributes(frame: bounds),
            children: viewNodes
        )
        
        rootController.update(with: rootNode, animated: self.nextViewHierarchyUpdateEnablesAppearanceTransitions, context: .init())

        isInsideUpdate = false
    }

    var currentNativeViewControllers: [(path: ElementPath, node: NativeViewController)] {

        /// Perform an update if needed so that the node hierarchy is fully populated.
        updateViewHierarchyIfNeeded()

        /// rootViewNode always contains a simple UIView – its children represent the
        /// views that are actually generated by the root element.
        return rootController.children
    }
}

extension BlueprintView {
    
    final class NativeViewController {

        private var viewDescription: ViewDescription

        private var layoutAttributes: LayoutAttributes
        
        private (set) var children: [(ElementPath, NativeViewController)]
        
        let view: UIView
        
        init(node: NativeViewNode, animated: Bool) {
            self.viewDescription = node.viewDescription
            self.layoutAttributes = node.layoutAttributes
            self.children = []
            self.view = node.viewDescription.build()
            
            self.update(with: node, animated: animated, context : UpdateContext())
        }

        fileprivate func canUpdateFrom(node: NativeViewNode) -> Bool {
            return node.viewDescription.viewType == type(of: view)
        }

        fileprivate func update(with node: NativeViewNode, animated: Bool, context : UpdateContext) {
            
            guard self.canUpdateFrom(node: node) else {
                fatalError("Blueprint Error: Cannot update a view from \(node.viewDescription.viewType) to \(type(of: view)). Types must match.")
            }
            
            // Update properties from the updated element node.

            viewDescription = node.viewDescription
            layoutAttributes = node.layoutAttributes
            
            viewDescription.apply(to: view)
            
            // Store children in a dictionary so they can later be accessed by their path.
            
            var oldChildren: [ElementPath: NativeViewController] = [:]
            oldChildren.reserveCapacity(children.count)
            
            for (path, childController) in children {
                oldChildren[path] = childController
            }
            
            // When the update pass is complete, this will contain all children.
            
            var newChildren: [(path: ElementPath, node: NativeViewController)] = []
            newChildren.reserveCapacity(node.children.count)
            
            var usedKeys: Set<ElementPath> = []
            usedKeys.reserveCapacity(node.children.count)
            
            for index in node.children.indices {
                let (path, child) = node.children[index]

                guard usedKeys.contains(path) == false else {
                    fatalError("Blueprint Error: Duplicate view identifier: \(path).")
                }
                usedKeys.insert(path)

                let contentView = node.viewDescription.contentView(in: self.view)
                
                var childContext = context
                                
                if let controller = oldChildren[path], controller.canUpdateFrom(node: child) {
                    
                    // We can update the existing view if it is of the same type as the last view at this path.

                    oldChildren.removeValue(forKey: path)
                    newChildren.append((path: path, node: controller))
                    
                    let layoutTransition: LayoutTransition
                    
                    if child.layoutAttributes != controller.layoutAttributes {
                        layoutTransition = child.viewDescription.layoutTransition
                    } else {
                        layoutTransition = .inherited
                    }
                    
                    // Update the layout of the view with the provided layout transformation.
                    // Attributes are applied inside the transition to preserve the desired animation.
                    
                    layoutTransition.perform {
                        child.layoutAttributes.apply(to: controller.view)

                        // Even though this view is already in the hierarchy,
                        // re-inserting the subview ensures we map z-ordering of the hierarchy.
                        contentView.insertSubview(controller.view, at: index)

                        controller.update(with: child, animated: animated, context: childContext)
                    }
                } else {
                    // ...otherwise, we will make a new view.
                    // The `for` loop below will handle cleaning up the old view.
                    
                    let transition = child.viewDescription.onAppear
                    let controller = NativeViewController(node: child, animated: animated)
                    
                    newChildren.append((path: path, node: controller))
                    
                    // Before we add the view to the hierarchy, ensure it is
                    // sized, positioned, etc, correctly.
                    
                    UIView.performWithoutAnimation {
                        child.layoutAttributes.apply(to: controller.view)
                    }
                    
                    contentView.insertSubview(controller.view, at: index)
                    
                    childContext.add(appearanceTransition: transition)
                    
                    controller.update(with: child, animated: animated, context: childContext)
                    
                    // Allow the appearance transition, if any, to take effect.
                    
                    if let transition = transition, animated, context.animate(transition) {
                        transition.animate(
                            direction: .appearing,
                            with: controller.view,
                            layoutAttributes: child.layoutAttributes
                        )
                    }
                }
            }
            
            // Finally, any children remaining in `oldChildren` should be removed from the hierarchy.
            // They are left over from the previous element hierarchy.
            
            for controller in oldChildren.values {
                let transition = controller.viewDescription.onDisappear
                                
                if let transition = transition, animated {
                    transition.animate(
                    direction: .disappearing,
                    with: controller.view,
                    layoutAttributes: controller.layoutAttributes,
                    completion: { _ in
                        controller.view.removeFromSuperview()
                    })
                } else {
                    controller.view.removeFromSuperview()
                }
            }
            
            children = newChildren
        }
    }
    
    fileprivate struct UpdateContext {
        private var parentAppearanceTransitions : [TransitionAnimation] = []
        
        mutating func add(appearanceTransition: TransitionAnimation?) {
            
            guard let transition = appearanceTransition else {
                return
            }
            
            self.parentAppearanceTransitions.append(transition)
        }
        
        func animate(_ transition : TransitionAnimation) -> Bool {
            switch transition.performing {
            case .always: return true
            case .ifNotNested: return self.parentAppearanceTransitions.isEmpty
            }
        }
    }
}
