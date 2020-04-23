//
//  Debugging.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 4/18/20.
//

import Foundation

import BlueprintUI
import BlueprintUICommonControls


public final class DebuggingSetup : NSObject, BlueprintUI.DebuggingSetup {
    
    @objc public static func setup() {
        DebuggingSupport.viewDescriptionProvider = { other, element, bounds, debugging in
            ViewDescription(Debugging.DebuggingWrapper.self) {
                $0.builder = {
                    Debugging.DebuggingWrapper(frame: bounds, containing: other, for: element, debugging: debugging)
                }
                
                $0.contentView = {
                    if let other = other, let contained = $0.containedView {
                        return other.contentView(in: contained)
                    } else {
                        return $0
                    }
                }
                
                $0.apply {
                    guard let other = other, let view = $0.containedView else {
                        return
                    }

                    other.apply(to: view)
                }
            }
        }
    }
}


extension Debugging {
    final class DebuggingWrapper : UIView {
       
        let elementInfo : ElementInfo
        let debugging : Debugging
        
        struct ElementInfo {
            var element : Element
            var isViewBacked : Bool
        }
        
        let containedView : UIView?
        private let infoView : InfoView
        
        /// TODO: Rename me!
        let longPress : UITapGestureRecognizer
        
        var isSelected : Bool = false {
            didSet {
                guard oldValue != self.isSelected else {
                    return
                }
                
                self.updateIsSelected()
            }
        }
        
        private func updateIsSelected() {
            
            if self.isSelected {
                self.layer.borderWidth = debugging.isIn3DPreview ? 3.0 : 2.0
                self.layer.cornerRadius = 3.0
                
                self.layer.borderColor = UIColor.systemBlue.cgColor
            } else {
                self.layer.borderWidth = debugging.isIn3DPreview ? 2.0 : 1.0
                self.layer.cornerRadius = 3.0
                
                if self.elementInfo.isViewBacked {
                    self.layer.borderColor = UIColor.systemBlue.withAlphaComponent(debugging.isIn3DPreview ? 0.6 : 0.4).cgColor
                    self.backgroundColor = UIColor.systemBlue.withAlphaComponent(debugging.isIn3DPreview ? 0.2 : 0.10)
                } else {
                    self.layer.borderColor = UIColor.black.withAlphaComponent(debugging.isIn3DPreview ? 0.3 : 0.20).cgColor
                }
            }
            
            if debugging.isIn3DPreview {
                self.layer.shadowColor = UIColor(white: 0.6, alpha: 1.0).cgColor
                self.layer.shadowOpacity = 1.0
                self.layer.shadowRadius = 3.0
                self.layer.shadowOffset = CGSize(width: 0.0, height: 16.0)
                self.layer.shadowPath = UIBezierPath(ovalIn: CGRect(x: 0.0, y: self.bounds.height, width: self.bounds.width, height: 4.0)).cgPath
            }
        }
        
        init(frame: CGRect, containing : ViewDescription?, for element : Element, debugging : Debugging) {
            
            if let containing = containing {
                let view = containing.build()
                view.frame = CGRect(origin: .zero, size: frame.size)
                
                self.containedView = view
            } else {
                self.containedView = nil
            }
            
            self.elementInfo = ElementInfo(
                element: element,
                isViewBacked: element.backingViewDescription(bounds: frame, subtreeExtent: nil) != nil
            )
            
            self.infoView = InfoView(elementInfo: self.elementInfo)
            
            self.debugging = debugging
            
            self.longPress = UITapGestureRecognizer()
            
            super.init(frame: frame)

            if debugging.isIn3DPreview {
                self.addSubview(self.infoView)
            }
            
            if let view = self.containedView {
                self.addSubview(view)
            }
            
            self.longPress.addTarget(self, action: #selector(didLongPress))
            self.addGestureRecognizer(self.longPress)
            
            self.updateIsSelected()
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            self.containedView?.frame = self.bounds
                        
            let size = self.infoView.sizeThatFits(self.bounds.size)
            self.infoView.frame = CGRect(x: 0.0, y: self.bounds.height + 2.0, width: size.width, height: size.height)
        }
        
        required init?(coder: NSCoder) { fatalError() }
        
        @objc private func didLongPress() {
            
            guard self.longPress.state == .recognized else {
                return
            }
            
            let point = self.longPress.location(in: self)

            let subviews = self.views(at: point) {
                $0 is BlueprintView
            }

            let filtered : [DebuggingWrapper] = subviews.compactMap { view in
                if let view = view as? DebuggingWrapper {
                    return view
                } else {
                    return nil
                }
            }

            let elements : [Element] = filtered.map {
                $0.elementInfo.element
            }

            let nav = UINavigationController(rootViewController: ChooseElementViewController(elements: elements))

            let host = self.window?.rootViewController?.viewControllerToPresentOn

            host?.present(nav, animated: true)
            
            Self.selectedWrapper = self
        }
        
        private static weak var selectedWrapper : DebuggingWrapper? = nil {
            didSet {
                if let wrapper = self.selectedWrapper, self.selectedWrapper === oldValue {
                    let nav = UINavigationController(rootViewController: ElementInfoViewController(element: wrapper.elementInfo.element))

                    let host = wrapper.window?.rootViewController?.viewControllerToPresentOn

                    host?.present(nav, animated: true)
                } else {
                    oldValue?.isSelected = false
                    self.selectedWrapper?.isSelected = true
                }
            }
        }
        
        private final class InfoView : UIView {
            let elementInfo : ElementInfo
            
            private let content : BlueprintView
            
            init(elementInfo : ElementInfo) {
                self.elementInfo = elementInfo
                
                self.content = BlueprintView()
                self.content.isOpaque = false
                self.content.backgroundColor = .clear
                self.content.acceptsDebugMode = false
                
                super.init(frame: .zero)
                
                self.content.element = self.element
                
                self.addSubview(self.content)
            }
            
            required init?(coder: NSCoder) { fatalError() }
            
            override func layoutSubviews() {
                super.layoutSubviews()
                
                self.content.frame = self.bounds
            }
            
            override func sizeThatFits(_ size: CGSize) -> CGSize {
                return self.content.sizeThatFits(size)
            }
            
            private var element : Element {
                Box(
                    wrapping: Inset(
                        uniformInset: 2.0,
                        wrapping: Label(text: String(describing: type(of: self.elementInfo.element))) {
                            $0.font = .systemFont(ofSize: 7.0, weight: .semibold)
                            $0.color = UIColor.white
                            $0.lineBreakMode = .byTruncatingMiddle
                            //$0.adjustsFontSizeToFitWidth = true
                            //$0.minimumScaleFactor = 0.4
                        }
                    )
                ) {
                    if self.elementInfo.isViewBacked {
                        $0.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.6)
                        $0.borderStyle = .solid(color: UIColor.systemBlue, width: 1.0)
                    } else {
                        $0.backgroundColor = UIColor.lightGray.withAlphaComponent(0.8)
                        $0.borderStyle = .solid(color: UIColor.darkGray.withAlphaComponent(0.8), width: 1.0)
                    }
                    
                    $0.cornerStyle = .rounded(radius: 3.0)
                }
            }
        }
    }
}


fileprivate extension UIViewController {
    var viewControllerToPresentOn : UIViewController {
        var toPresentOn : UIViewController = self
        
        repeat {
            if let presented = toPresentOn.presentedViewController {
                toPresentOn = presented
            } else {
                break
            }
        } while true

        return toPresentOn
    }
}


final class ChooseElementViewController : UIViewController {
    
    let elements : [Element]
        
    let blueprintView = BlueprintView()
    
    init(elements : [Element]) {
        self.elements = elements
        
        super.init(nibName: nil, bundle: nil)
        
        self.title = "Choose Element"
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func loadView() {
        self.view = self.blueprintView
        
        self.blueprintView.element = Content(elements: self.elements, presentOn: self)
        
        self.blueprintView.layoutIfNeeded()
    }
    
    struct Content : ProxyElement {
        let elements : [Element]
        weak var presentOn : UIViewController?
        
        var elementRepresentation: Element {
            DebuggingScreenContent(
                sections: [
                    .init(
                        title: "Elements",
                        detail:
                        """
                        You selected an element which overlays other elements entirely contained within the selected elements frame.

                        The below list is all those elements; please click on the one you want to inspect!
                        """,
                        element: Column {
                            $0.minimumVerticalSpacing = 20.0
                            
                            for element in self.elements {
                                $0.add(
                                    child: DebuggingScreenContent.ElementRow(
                                        element: element,
                                        depth: 0,
                                        onTap: { element in
                                            self.presentOn?.viewControllerToPresentOn.present(
                                                UINavigationController(rootViewController: ElementInfoViewController(element: element)),
                                                animated: true
                                            )
                                        }
                                    )
                                )
                            }
                        }
                    )
                ]
            )
        }
    }
}


struct DebuggingScreenContent : ProxyElement {
    
    var sections : [Section]
    
    static var sideInset : CGFloat = 10.0
    
    var elementRepresentation: Element {
        Box(
            backgroundColor: UIColor(white: 0.90, alpha: 1.0),
            wrapping: self.content
        )
    }
    
    private var content : Element {
        
        let allSections = Column {
            $0.horizontalAlignment = .fill
            $0.minimumVerticalSpacing = 20.0
                                
            for section in self.sections {
                $0.add(child: section)
            }
        }
        
        return ScrollView(wrapping: allSections) {
            $0.contentSize = .fittingHeight
            $0.contentInset = .init(top: 10.0, left: 0.0, bottom: 10.0, right: 0.0)
        }
    }

    struct ContentBox : ProxyElement {
        var sideInsets : Bool
        var wrapping : Element
        
        var elementRepresentation: Element {
            let inset = self.sideInsets ? DebuggingScreenContent.sideInset : 0.0
            
            return Box(
                wrapping: Inset(
                    insets: UIEdgeInsets(top: 20.0, left: inset, bottom: 20.0, right: inset),
                    wrapping: self.wrapping
                    )
                ) { box in
                    box.shadowStyle = .simple(
                        radius: 2.0,
                        opacity: 0.25,
                        offset: CGSize(width: 0.0, height: 1.0),
                        color: .black
                    )
                    
                    box.backgroundColor = .white
            }
        }
    }
    
    struct Section : ProxyElement {
        
        var title : String
        var detail : String = ""
        var element : Element
        var horizontallyInsetsContent : Bool = true
        
        init(
            title : String,
            detail : String = "",
            element : Element,
            horizontallyInsetsContent : Bool = true
        ) {
            self.title = title
            self.detail = detail
            self.element = element
            self.horizontallyInsetsContent = horizontallyInsetsContent
        }
        
        var elementRepresentation: Element {
            Column {
                $0.horizontalAlignment = .fill
                
                $0.add(
                    // TODO: Split into header type
                    child: Inset(
                        sideInsets: DebuggingScreenContent.sideInset,
                        wrapping: Column {
                            
                            $0.add(child: Label(text: self.title) {
                                $0.font = .systemFont(ofSize: 28.0, weight: .bold)
                            })
                            
                            $0.add(child: Spacer(size: CGSize(width: 0.0, height: 5.0)))
                            
                            if self.detail.isEmpty == false {
                                $0.add(child: Label(text: self.detail) {
                                    $0.font = .systemFont(ofSize: 13.0, weight: .regular)
                                    $0.color = .darkGray
                                })
                                
                                $0.add(child: Spacer(size: CGSize(width: 0.0, height: 10.0)))
                            }
                        }
                    )
                )
                
                $0.add(child: ContentBox(
                    sideInsets: self.horizontallyInsetsContent,
                    wrapping: self.element
                ))
            }
        }
    }
    
    struct ElementRow : ProxyElement {
        var element : Element
        var depth : Int
        
        var onTap : (Element) -> ()

        var elementRepresentation: Element {
            Row {
                $0.verticalAlignment = .fill
                $0.horizontalUnderflow = .growUniformly
                
                let spacer = Spacer(size: CGSize(width: CGFloat(depth) * 15.0, height: 0.0))
                $0.add(growPriority: 0.0, shrinkPriority: 0.0, child: spacer)
                
                let box = Box(backgroundColor: .init(white: 0.0, alpha: 0.05), wrapping: self.content)
                
                $0.add(growPriority: 1.0, shrinkPriority: 1.0, child: box)
            }
        }
        
        private var content : Element {
            Row {
                $0.verticalAlignment = .fill
                $0.horizontalUnderflow = .justifyToStart
                
                $0.add(
                    child: Rule(orientation: .vertical, color: .darkGray, thickness: .points(2.0))
                )
                
                let elementInfo = Column {
                        
                    $0.add(child: Label(text: String(describing: type(of: self.element))) {
                        $0.font = .systemFont(ofSize: 18.0, weight: .semibold)
                        $0.color = .systemBlue
                    })
                    
                    $0.add(child: Spacer(size: CGSize(width: 0.0, height: 5.0)))
                    
                    $0.add(
                        child: Tappable(
                            onTap: { self.onTap(self.element) },
                            wrapping: Box(
                                backgroundColor: .white,
                                wrapping: UserInteraction(
                                    enabled: false,
                                    wrapping: self.element
                                )
                            )
                        )
                    )
                }
                
                $0.add(
                    child: Inset(uniformInset: 5.0, wrapping: elementInfo)
                )
            }
        }
    }
}


final class ElementInfoViewController : UIViewController {
    
    let element : Element
        
    let blueprintView = BlueprintView()
    
    init(element : Element) {
        self.element = element
        
        super.init(nibName: nil, bundle: nil)
        
        self.title = "Inspector"
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func loadView() {
        self.view = self.blueprintView
        //self.blueprintView.debugging.showElementFrames = .viewBacked
        
        self.blueprintView.element = PreviewElement(
            presenting: self.element,
            presentOn: self
        )
        
        self.blueprintView.layoutIfNeeded()
    }
    
    struct PreviewElement : ProxyElement {
        var presenting : Element
        
        weak var presentOn : UIViewController?
        
        var elementRepresentation: Element {
            DebuggingScreenContent(
                sections: [
                    .init(
                        title: "Preview",
                        element: Preview(presenting: self.presenting)
                    ),
                    
                    .init(
                        title: "Layers",
                        element: ThreeDVisualization(presenting: self.presenting)
                    ),
                    
                    .init(
                        title: "Hierarchy",
                        element: RecursiveElements(presenting: self.presenting, onTap: { element in
                            self.presentOn?.present(
                                UINavigationController(rootViewController: ElementInfoViewController(element: element)),
                                animated: true
                            )
                        })
                    ),
                ]
            )
        }
        
        struct Preview : ProxyElement {
            var presenting : Element
            
            var elementRepresentation: Element {
                ConstrainedSize(
                    height: .atLeast(100.0),
                    wrapping: Centered(Box(wrapping: self.presenting) {
                        $0.borderStyle = .solid(color: UIColor(white: 0.0, alpha: 0.25), width: 1.0)
                        $0.cornerStyle = .rounded(radius: 4.0)
                    })
                )
            }
        }
        
        struct ThreeDVisualization : ProxyElement {
            var presenting : Element
            
            var elementRepresentation: Element {
                let snapshot = FlattenedElementSnapshot(
                    element: self.presenting,
                    sizeConstraint: SizeConstraint(UIScreen.main.bounds.size)
                )
                
                return ThreeDElementVisualization(snapshot: snapshot)
            }
        }
        
        struct RecursiveElements : ProxyElement {
            var presenting : Element
            var onTap : (Element) -> ()
            
            var elementRepresentation: Element {
                Column {
                    $0.horizontalAlignment = .fill
                    $0.minimumVerticalSpacing = 10.0
                    
                    let list = self.presenting.recursiveElementList()
                    
                    for element in list {
                        $0.add(
                            child: DebuggingScreenContent.ElementRow(
                                element: element.element,
                                depth: element.depth,
                                onTap: self.onTap
                            )
                        )
                    }
                }
            }
        }
    }
}

fileprivate struct RecursedElement {
    var element : Element
    var depth : Int
}

fileprivate extension Element {
    
    func recursiveElementList() -> [RecursedElement] {
        var list = [RecursedElement]()
        
        self.appendTo(recursiveElementList: &list, depth: 0)
        
        return list
    }
    
    func appendTo(recursiveElementList list : inout [RecursedElement], depth : Int) {
        list.append(RecursedElement(element: self, depth: depth))
        
        self.content.childElements.forEach {
            $0.appendTo(recursiveElementList: &list, depth: depth + 1)
        }
    }
}

fileprivate struct ThreeDElementVisualization : Element {
    
    var snapshot : FlattenedElementSnapshot
    
    var content: ElementContent {
        ElementContent { constraint in
                        
            let scaling = constraint.maximum.width / (self.snapshot.size.width > 0.0 ? self.snapshot.size.width : 1.0)
            
            let scaledWidth = self.snapshot.size.width * scaling
            let scaledHeight = self.snapshot.size.height * scaling
            
            return CGSize(
                width: scaledWidth,
                height: max(scaledWidth, scaledHeight)
            )
        }
    }
    
    func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        ViewDescription(View.self) {
            $0.builder = {
                View(snapshot: self.snapshot)
            }
        }
    }
    
    final class View : UIView {
        private let snapshot : FlattenedElementSnapshot
        private let snapshotHost : HostView
        
        private let rotation : UIPanGestureRecognizer
        private let pan : UIPanGestureRecognizer
        
        private var transformState : TransformState = .standard
        
        struct TransformState : Equatable {
            
            // 1.0 == 180 degrees
            var rotationX : CGFloat
            // 1.0 == 180 degrees
            var rotationY : CGFloat
            var translation : CGPoint
            
            static var standard : TransformState {
                TransformState(
                    rotationX: 45 / CGFloat.pi / 180,
                    rotationY: 0,
                    translation: .zero
                )
            }
            
            func transform(scale : CGFloat? = nil) -> CATransform3D {
                
                var t = CATransform3DIdentity
                
                // https://stackoverflow.com/questions/3881446/meaning-of-m34-of-catransform3d
                t.m34 = -1.0 / 2000.0
                
                if let scale = scale {
                    t = CATransform3DScale(t, scale, scale, scale)
                }
                
                t = CATransform3DTranslate(t, self.translation.x, self.translation.y, 0.0)
                t = CATransform3DRotate(t, self.rotationX * CGFloat.pi, 1.0, 0.0, 0.0)
                t = CATransform3DRotate(t, self.rotationY * CGFloat.pi, 0.0, 1.0, 0.0)
                
                return t
            }
        }
        
        init(snapshot : FlattenedElementSnapshot) {
            
            self.snapshot = snapshot
            self.snapshotHost = HostView(snapshot: self.snapshot)
            
            self.rotation = UIPanGestureRecognizer()
            self.rotation.maximumNumberOfTouches = 1;

            self.pan = UIPanGestureRecognizer()
            self.pan.require(toFail: self.rotation)
            
            super.init(frame: CGRect(origin: .zero, size: self.snapshot.size))
        
            self.addSubview(self.snapshotHost)
            
            self.rotation.addTarget(self, action: #selector(handleRotation))
            self.pan.addTarget(self, action: #selector(handlePan))
            
            self.addGestureRecognizer(self.rotation)
            self.addGestureRecognizer(self.pan)
        }
        
        required init?(coder: NSCoder) { fatalError() }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            self.snapshotHost.frame.origin = CGPoint(
                x: round((self.bounds.width - self.snapshotHost.frame.width) / 2.0),
                y: round((self.bounds.height - self.snapshotHost.frame.height) / 2.0)
            )
            
            self.updateSublayerTransform(animated: false)
        }
        
        @objc private func handleRotation() {
            
            let dragFactor : CGFloat = 2.0
            
            self.transformState.rotationX -= (self.rotation.translation(in: self).y / self.bounds.size.width) / dragFactor
            self.transformState.rotationY += (self.rotation.translation(in: self).x / self.bounds.size.width) / dragFactor
            
            self.rotation.setTranslation(.zero, in: self)
            
            self.updateSublayerTransform(animated: false)
        }
        
        @objc private func handlePan() {
            
            let dragFactor : CGFloat = 2.0
                        
            self.transformState.translation.x += self.pan.translation(in: self).x / dragFactor
            self.transformState.translation.y += self.pan.translation(in: self).y / dragFactor
            
            self.pan.setTranslation(.zero, in: self)
            
            self.updateSublayerTransform(animated: false)
        }
        
        private func updateSublayerTransform(animated : Bool) {
            // Apply once so that we have the updated frames to use when calculating visible positions.
            self.snapshotHost.layer.sublayerTransform = self.transformState.transform()
            // Now that the transform is applied, update the scale using the visible positions.
            self.snapshotHost.layer.sublayerTransform = self.transformState.transform(scale: self.snapshotHost.scaleToShowAllSubviews(in: self))
        }
        
        final class HostView : UIView {
            private let snapshot : FlattenedElementSnapshot
            
            init(snapshot : FlattenedElementSnapshot) {
                self.snapshot = snapshot
                
                super.init(frame: CGRect(origin: .zero, size: self.snapshot.size))
                
                for view in snapshot.flatHierarchySnapshot {
                    self.addSubview(view.view)
                    view.view.frame = view.frame
                    view.view.layer.zPosition = 20 * CGFloat(view.hierarchyDepth)
                }
            }
            
            required init?(coder: NSCoder) { fatalError() }
            
            override func sizeThatFits(_ size: CGSize) -> CGSize {
                self.snapshot.size
            }
            
            func scaleToShowAllSubviews(in parent : UIView) -> CGFloat {
            
                var union : CGRect = .zero
                
                self.recurse { view in
                    let rect = view.convert(view.bounds, to: parent)
                    union = union.union(rect)
                }
                
                let widthScale = union.width / parent.bounds.width
                let heightScale = union.height / parent.bounds.height
                
                let maxScale = max(widthScale, heightScale)
                
                return 1.0 / maxScale
            }
        }
    }
}

fileprivate struct FlattenedElementSnapshot {
    let element : Element
    let flatHierarchySnapshot : [ViewSnapshot]
    let size : CGSize
    
    init(element : Element, sizeConstraint : SizeConstraint) {
        self.element = element
        
        self.size = self.element.content.measure(in: sizeConstraint)
        
        let view = BlueprintView(frame: CGRect(origin: .zero, size: self.size))
        view.debugging.showElementFrames = .all
        view.debugging.isIn3DPreview = true
        
        view.element = self.element
        view.layoutIfNeeded()
        
        var snapshot = [ViewSnapshot]()
        
        view.buildFlatHierarchySnapshot(in: &snapshot, rootView: view, depth: 0)
        
        self.flatHierarchySnapshot = snapshot
    }
    
    struct ViewSnapshot {
        var element : Element
        var view : UIView
        var frame : CGRect
        var hierarchyDepth : Int
    }
}

fileprivate extension UIView {
    
    func recurse(with block : (UIView) -> ()) {
        block(self)
        
        for view in self.subviews {
            view.recurse(with: block)
        }
    }
    
    func superview(passing : (UIView) -> Bool) -> UIView? {
        
        var current = self.superview
        
        while let superview = current {
            if passing(superview) {
                return superview
            }
            
            current = superview.superview
        }
        
        return nil
    }
    
    func views(at point : CGPoint, below superview : (UIView) -> Bool) -> [UIView] {
        var views = [UIView]()
        
        let startingView = self.superview(passing: superview) ?? self
        
        startingView.recurse { view in
            let isPointInside = view.point(inside: self.convert(point, to: view), with: nil)
            
            let isSmallerThanView = self.frame.contains(view.convert(view.bounds, to: self))
            
            if isPointInside && isSmallerThanView {
                views.append(view)
            }
        }
        
        return views
    }
    
    func buildFlatHierarchySnapshot(in list : inout [FlattenedElementSnapshot.ViewSnapshot], rootView : UIView, depth : Int) {
        
        if let self = self as? Debugging.DebuggingWrapper {
            let snapshot = FlattenedElementSnapshot.ViewSnapshot(
                element: self.elementInfo.element,
                view: self,
                frame: self.convert(self.bounds, to: rootView),
                hierarchyDepth: depth
            )
            
            list.append(snapshot)
        }
        
        for view in self.subviews {
            view.buildFlatHierarchySnapshot(in: &list, rootView: rootView, depth: depth + 1)
        }
        
        if self is Debugging.DebuggingWrapper {
            self.removeFromSuperview()
        }
    }
    
    func toImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: self.bounds.size)
        
        return renderer.image {
            self.layer.render(in: $0.cgContext)
        }
    }
}
