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

    private var neededUpdateType : UpdateType
    
    private var lastViewHierarchyUpdateBounds: CGRect

    /// Used to detect reentrant updates
    private var isInsideUpdate: Bool = false

    private let rootController: NativeViewController
    
    /// The root element that is displayed within the view.
    public var element: Element? {
        set {
            self.setElement(animated: UIView.isInAnimationBlock, newValue)
        }
        get {
            return self._element
        }
    }
    
    private var _element : Element?
    
    public func setElement(animated : Bool = UIView.isInAnimationBlock, _ element : Element?)
    {
        _element = element
        
        neededUpdateType = .needsViewHierarchyUpdate(animated: animated)

        if UIView.isInAnimationBlock {
            // If we're in an animation block, we want to inherit that
            // animation – perform the requested element update right now.
            
            updateViewHierarchyIfNeeded()
        } else {
            // In this case, we'll wait for the next layout pass to complete to drive an update.
            
            setNeedsLayout()
        }
    }

    /// Instantiates a view with the given element
    ///
    /// - parameter element: The root element that will be displayed in the view.
    /// - parameter animated: If appearance and layout transitions should occur during the first layout.
    ///
    public required init(element: Element?, frame : CGRect = .zero, animateInitialLayout : Bool = UIView.isInAnimationBlock) {
        
        _element = element
        
        neededUpdateType = .needsViewHierarchyUpdate(animated: animateInitialLayout)
        
        lastViewHierarchyUpdateBounds = .zero
        
        rootController = NativeViewController(
            node: NativeViewNode(
                content: UIView.describe() { _ in },
                layoutAttributes: LayoutAttributes(),
                children: []
            ),
            animated: animateInitialLayout,
            parentContext: UpdateContext(),
            update: true
        )
    
        super.init(frame: frame)
        
        self.backgroundColor = .white
        addSubview(rootController.view)
    }

    public override convenience init(frame: CGRect) {
        self.init(element: nil, frame: frame)
    }

    @available(*, unavailable)
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Forwarded to the `measure(in:)` implementation of the root element.
    override public func sizeThatFits(_ size: CGSize) -> CGSize {
        
        guard let element = element else {
            return .zero
        }
        
        let constraint = size == .zero ? SizeConstraint.unconstrained : SizeConstraint(size)
        
        return element.content.measure(in: constraint)
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        updateViewHierarchyIfNeeded()
    }
    
    private func updateViewHierarchyIfNeeded() {
        
        guard neededUpdateType != .none || bounds != lastViewHierarchyUpdateBounds else {
            return
        }
                        
        guard isInsideUpdate == false else {
            fatalError("Reentrant updates are not supported in BlueprintView. Ensure that view events from within the hierarchy are not synchronously triggering additional updates.")
        }
        
        let animated = neededUpdateType.animated

        isInsideUpdate = true
        neededUpdateType = .none
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
        
        rootController.update(
            with: rootNode,
            animated: animated,
            parentContext: .init()
        )

        isInsideUpdate = false
    }

    var currentNativeViewControllers: [NativeViewController.Child] {

        /// Perform an update if needed so that the node hierarchy is fully populated.
        updateViewHierarchyIfNeeded()

        /// rootViewNode always contains a simple UIView – its children represent the
        /// views that are actually generated by the root element.
        return rootController.children
    }
    
    public override var debugDescription: String {
        return self.recursiveViewDescription
    }
}


extension BlueprintView {
    
    public var recursiveViewDescription : String {
        
        var descriptions = [RecursiveDescription]()
        
        self.rootController.appendToRecursiveDescription(depth: 0, descriptions: &descriptions)
        
        let strings : [String] = descriptions.map {
            Array(repeating: "  ", count: $0.depth).joined() + $0.description
        }
        
        return strings.joined(separator: "\n")
    }
    
    fileprivate struct RecursiveDescription {
        var depth : Int
        var description : String
    }
}


extension BlueprintView.NativeViewController {
    
    fileprivate func appendToRecursiveDescription(depth : Int, descriptions : inout [BlueprintView.RecursiveDescription]) {
        
        descriptions.append(BlueprintView.RecursiveDescription(
            depth: depth,
            description: self.view.shortDescription
        ))
        
        children.forEach {
            $0.controller.appendToRecursiveDescription(depth: depth + 1, descriptions: &descriptions)

        }
    }
}

extension UIView {
    fileprivate var shortDescription : String {
        "<\(type(of:self)): frame = \(self.frame)>"
    }
}



extension BlueprintView {
    
    private enum UpdateType : Equatable {
        case none
        case needsViewHierarchyUpdate(animated : Bool)
        
        var animated : Bool {
            switch self {
            case .none: return false
            case .needsViewHierarchyUpdate(let animated): return animated
            }
        }
    }
    
    final class NativeViewController {

        let view: UIView
        
        private var viewDescription: ViewDescription
        private var layoutAttributes: LayoutAttributes
        
        private (set) var children: [Child]
        
        struct Child {
            var path : ElementPath
            var controller : NativeViewController
        }
        
        init(node: NativeViewNode, animated: Bool, parentContext : UpdateContext, update: Bool) {
            self.viewDescription = node.viewDescription
            self.layoutAttributes = node.layoutAttributes
            self.children = []
            self.view = node.viewDescription.build()
            
            if update {
                self.update(with: node, animated: animated, parentContext : parentContext)
            }
        }

        fileprivate func canUpdateFrom(node: NativeViewNode) -> Bool {
            return node.viewDescription.viewType == type(of: view)
        }

        fileprivate func update(with node: NativeViewNode, animated: Bool, parentContext : UpdateContext) {
                        
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
            
            children.forEach {
                oldChildren[$0.path] = $0.controller
            }
            
            // When the update pass is complete, this will contain all children.
            
            var newChildren: [Child] = []
            newChildren.reserveCapacity(node.children.count)
            
            var usedKeys: Set<ElementPath> = []
            usedKeys.reserveCapacity(node.children.count)
            
            for index in node.children.indices {
                let (path, child) = node.children[index]

                guard usedKeys.contains(path) == false else {
                    fatalError("Blueprint Error: Duplicate view identifier: \(path).")
                }
                
                usedKeys.insert(path)
                
                var childContext = parentContext
                
                childContext.setAllowsAnimations(
                    with: node.viewDescription.allowsAnimations,
                    updateRequestedAnimations: animated
                )

                let contentView = node.viewDescription.contentView(in: self.view)
                                
                if let controller = oldChildren[path], controller.canUpdateFrom(node: child) {
                    
                    // We can update the existing view if it is of the same type as the last view at this path.

                    oldChildren.removeValue(forKey: path)
                    
                    newChildren.append(Child(
                        path: path,
                        controller: controller
                    ))
                    
                    // Get any needed layout transition for the current animation state.
                    
                    let layout : LayoutTransition = {
                        if childContext.allowsAnimations {
                            if child.layoutAttributes != controller.layoutAttributes {
                                return child.viewDescription.onLayout
                            } else {
                                return .inherited
                            }
                        } else {
                            return .none
                        }
                    }()
                    
                    // Update the layout of the view with the provided layout transformation.
                    // Attributes are applied inside the transition to preserve the desired animation.
                    
                    layout.perform {
                        child.layoutAttributes.apply(to: controller.view)

                        // Even though this view is already in the hierarchy,
                        // re-inserting the subview ensures we map z-ordering of the hierarchy.
                        contentView.insertSubview(controller.view, at: index)

                        controller.update(with: child, animated: animated, parentContext: childContext)
                    }
                } else {
                    // ...otherwise, we will make a new view.
                    // The `for` loop below will handle cleaning up the old view.
                                        
                    let transition = child.viewDescription.onAppear
                    
                    let controller = NativeViewController(
                        node: child,
                        animated: animated,
                        parentContext: childContext,
                        update: false
                    )
                    
                    newChildren.append(Child(
                        path: path,
                        controller: controller
                    ))
                    
                    childContext.didPerform(transition: transition)
                                        
                    // Before we add the view to the hierarchy, ensure it is
                    // sized, positioned, etc, correctly.
                    
                    UIView.performWithoutAnimation {
                        child.layoutAttributes.apply(to: controller.view)
                        contentView.insertSubview(controller.view, at: index)
                    }
                    
                    controller.update(with: child, animated: animated, parentContext: childContext)
                                        
                    // Allow the appearance transition, if any, to take effect.
                    
                    if let transition = transition {
                        if parentContext.shouldAnimate(transition) {
                            transition.animate(
                                direction: .appearing,
                                with: controller.view,
                                layoutAttributes: child.layoutAttributes
                            )
                        } else {
                            transition.skipAnimation(
                                direction: .appearing,
                                with: controller.view,
                                layoutAttributes: child.layoutAttributes
                            )
                        }
                    }
                }
            }
            
            // Finally, any children remaining in `oldChildren` should be removed from the hierarchy.
            // They are left over from the previous element hierarchy.
            
            for controller in oldChildren.values {
                self.removeChild(
                    node: node,
                    controller: controller,
                    animated: animated,
                    parentContext: parentContext
                )
            }
            
            children = newChildren
        }
        
        private func updateChild() {
        }
        
        private func insertChild() {
        }
        
        private func removeChild(
            node : NativeViewNode,
            controller : NativeViewController,
            animated : Bool,
            parentContext : UpdateContext
        ) {
            let transition = controller.viewDescription.onDisappear
            
            var childContext = parentContext
            
            // TODO: Likely move this back up a layer.
            childContext.setAllowsAnimations(
                with: node.viewDescription.allowsAnimations,
                updateRequestedAnimations: animated
            )
            
            if let transition = transition, parentContext.shouldAnimate(transition) {
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
    }
    
    
    struct UpdateContext {
        
        // MARK: Animations Enabled
        
        private(set) var allowsAnimations : Bool = true
        
        mutating func setAllowsAnimations(with allowsAnimations : Bool?, updateRequestedAnimations : Bool) {
            
            if updateRequestedAnimations {
                guard let allowsAnimations = allowsAnimations else {
                    return
                }
                
                self.allowsAnimations = allowsAnimations
            } else {
                self.allowsAnimations = false
            }
        }
        
        // MARK: Appearance Transitions
        
        private var hasParentAppearanceTransition : Bool = false
        
        mutating func didPerform(transition: TransitionAnimation?) {
            guard transition != nil else {
                return
            }
            
            self.hasParentAppearanceTransition = true
        }
        
        func shouldAnimate(_ transition : TransitionAnimation) -> Bool {
            guard self.allowsAnimations else {
                return false
            }
            
            switch transition.performing {
            case .always: return true
            case .ifNotNested: return self.hasParentAppearanceTransition == false
            }
        }
    }
}
