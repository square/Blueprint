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
public final class BlueprintView : UIView {
    
    //
    // MARK: Public Properties
    //
    
    /// The root element that is displayed within the view.
    public var element: Element? {
        set {
            self.set(element: newValue)
        }
        get {
            return self._element
        }
    }
    
    weak var delegate : BlueprintViewDelegate? = nil {
        didSet {
            self.hierarchyPresenter.delegate = self.delegate
        }
    }
    
    //
    // MARK: Private Properties
    //
    
    private var needsViewHierarchyUpdate: Bool = true
    private var nextViewHierarchyUpdateEnablesAppearanceTransitions: Bool = false
    
    private var lastViewHierarchyUpdateBounds: CGRect = .zero

    /// Used to detect reentrant updates
    private var isInsideUpdate: Bool = false

    private let hierarchyPresenter : ViewHierarchyPresenter
    
    private var _element : Element?
    
    //
    // MARK: Initialization
    //

    /// Instantiates a view with the given element
    ///
    /// - parameter element: The root element that will be displayed in the view.
    
    public convenience init(element: Element?, animated: Bool = UIView.isInAnimationBlock) {
        self.init(element: element, delegate: nil, animated: animated)
    }
    
    internal init(element: Element?, delegate : BlueprintViewDelegate?, animated: Bool = UIView.isInAnimationBlock) {
        
        self.delegate = delegate
        
        _element = element
        
        self.nextViewHierarchyUpdateEnablesAppearanceTransitions = animated
        
        hierarchyPresenter = ViewHierarchyPresenter(
            node: NativeViewNode(
                content: UIView.describe() { _ in },
                layoutAttributes: LayoutAttributes(),
                children: []
            ),
            delegate: self.delegate,
            animated: animated
        )
    
        super.init(frame: CGRect.zero)
        
        self.backgroundColor = .white
        addSubview(hierarchyPresenter.view)
    }

    public override convenience init(frame: CGRect) {
        self.init(element: nil)
        self.frame = frame
    }

    @available(*, unavailable)
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //
    // MARK: Public Methods
    //
    
    public func set(animated : Bool = UIView.isInAnimationBlock, element: Element?)
    {
        _element = element
        
        self.nextViewHierarchyUpdateEnablesAppearanceTransitions = animated
        
        self.setNeedsViewHierarchyUpdate()
    }
    
    //
    // MARK: UIView
    //

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
    
    //
    // MARK: Private Methods
    //
    
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
        
        hierarchyPresenter.view.frame = bounds
        
        let rootNode = NativeViewNode(
            content: UIView.describe() { _ in },
            layoutAttributes: LayoutAttributes(frame: bounds),
            children: viewNodes
        )
        
        hierarchyPresenter.update(with: rootNode, animated: self.nextViewHierarchyUpdateEnablesAppearanceTransitions, context: .init())

        isInsideUpdate = false
    }

    var currentHierarchyState: [(path: ElementPath, node: ViewHierarchyPresenter)] {

        /// Perform an update if needed so that the node hierarchy is fully populated.
        updateViewHierarchyIfNeeded()

        /// rootViewNode always contains a simple UIView – its children represent the
        /// views that are actually generated by the root element.
        return hierarchyPresenter.children
    }
}


extension BlueprintView {
    
    final class ViewHierarchyPresenter {
        
        fileprivate weak var delegate : BlueprintViewDelegate? {
            didSet {
                for (_, presenter) in self.children {
                    presenter.delegate = self.delegate
                }
            }
        }

        private var viewDescription: ViewDescription

        private var layoutAttributes: LayoutAttributes
        
        private (set) var children: [(ElementPath, ViewHierarchyPresenter)]
        
        let view: UIView
        
        init(node: NativeViewNode, delegate: BlueprintViewDelegate?, animated: Bool) {
            
            self.delegate = delegate
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
            
            var oldChildren: [ElementPath: ViewHierarchyPresenter] = [:]
            oldChildren.reserveCapacity(children.count)
            
            for (path, childPresenter) in children {
                oldChildren[path] = childPresenter
            }
            
            // When the update pass is complete, this will contain all children.
            
            var newChildren: [(path: ElementPath, node: ViewHierarchyPresenter)] = []
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
                                
                if let presenter = oldChildren[path], presenter.canUpdateFrom(node: child) {
                    
                    // We can update the existing view if it is of the same type as the last view at this path.

                    oldChildren.removeValue(forKey: path)
                    newChildren.append((path: path, node: presenter))
                    
                    let layoutTransition: LayoutTransition
                    
                    if child.layoutAttributes != presenter.layoutAttributes {
                        layoutTransition = child.viewDescription.layoutTransition
                    } else {
                        layoutTransition = .inherited
                    }
                    
                    // Update the layout of the view with the provided layout transformation.
                    // Attributes are applied inside the transition to preserve the desired animation.
                    
                    layoutTransition.perform {
                        child.layoutAttributes.apply(to: presenter.view)

                        // Even though this view is already in the hierarchy,
                        // re-inserting the subview ensures we map z-ordering of the hierarchy.
                        contentView.insertSubview(presenter.view, at: index)

                        presenter.update(with: child, animated: animated, context: childContext)
                    }
                } else {
                    // ...otherwise, we will make a new view.
                    // The `for` loop below will handle cleaning up the old view.
                    
                    let transition = child.viewDescription.onAppear
                    let presenter = ViewHierarchyPresenter(node: child, delegate: self.delegate, animated: animated)
                    
                    newChildren.append((path: path, node: presenter))
                    
                    // Before we add the view to the hierarchy, ensure it is
                    // sized, positioned, etc, correctly.
                    
                    UIView.performWithoutAnimation {
                        child.layoutAttributes.apply(to: presenter.view)
                    }
                    
                    contentView.insertSubview(presenter.view, at: index)
                    
                    childContext.add(appearanceTransition: transition)
                    
                    presenter.update(with: child, animated: animated, context: childContext)
                    
                    // Allow the appearance transition, if any, to take effect.
                    
                    if let transition = transition, animated, context.animate(transition) {
                        transition.animate(
                            direction: .appearing,
                            with: presenter.view,
                            layoutAttributes: child.layoutAttributes
                        )
                    }
                }
            }
            
            // Finally, any children remaining in `oldChildren` should be removed from the hierarchy.
            // They are left over from the previous element hierarchy.
            
            for presenter in oldChildren.values {
                let transition = presenter.viewDescription.onDisappear
                                
                if let transition = transition, animated {
                    transition.animate(
                    direction: .disappearing,
                    with: presenter.view,
                    layoutAttributes: presenter.layoutAttributes,
                    completion: { _ in
                        presenter.view.removeFromSuperview()
                    })
                } else {
                    presenter.view.removeFromSuperview()
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
