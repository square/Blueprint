//
//  Debugging.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 4/18/20.
//

import Foundation


public struct Debugging : Equatable {
    
    public var showElementFrames : ShowElementFrames
    
    public enum ShowElementFrames : Equatable {
        case none
        case all
        case viewBacked
    }
    
    public var longPressForDebugger : Bool
    public var exploreElementHistory : Bool
    
    public init(
        showElementFrames : ShowElementFrames = .none,
        longPressForDebugger : Bool = false,
        exploreElementHistory : Bool = false
    )
    {
        self.showElementFrames = showElementFrames
        self.longPressForDebugger = longPressForDebugger
        self.exploreElementHistory = exploreElementHistory
    }
}

extension Debugging {
    static func viewDescriptionWrapping(other : ViewDescription?, for element : Element, bounds : CGRect) -> ViewDescription {
        
        ViewDescription(DebuggingWrapper.self) {
            $0.builder = {
                DebuggingWrapper(frame: bounds, containing: other, for: element)
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
    
    final class DebuggingWrapper : UIView {
        
        let elementInfo : ElementInfo
        
        struct ElementInfo {
            var element : Element
            var isViewBacked : Bool
        }
        
        let containedView : UIView?
        
        let longPress : UITapGestureRecognizer
        
        var isSelected : Bool = false{
            didSet {
                guard oldValue != self.isSelected else {
                    return
                }
                
                self.updateIsSelected()
            }
        }
        
        private func updateIsSelected() {
            
            if self.isSelected {
                self.layer.borderWidth = 2.0
                self.layer.cornerRadius = 2.0
                
                self.layer.borderColor = UIColor.systemBlue.cgColor
            } else {
                self.layer.borderWidth = 1.0
                self.layer.cornerRadius = 2.0
                
                if self.elementInfo.isViewBacked {
                    self.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.4).cgColor
                    self.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.10)
                } else {
                    self.layer.borderColor = UIColor.black.withAlphaComponent(0.20).cgColor
                }
            }
        }
        
        init(frame: CGRect, containing : ViewDescription?, for element : Element) {
            
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
            
            self.longPress = UITapGestureRecognizer()
            
            super.init(frame: frame)

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
        }
        
        required init?(coder: NSCoder) { fatalError() }
        
        @objc private func didLongPress() {
            
            guard self.longPress.state == .recognized else {
                return
            }
            
            Self.selectedWrapper = self
        }
        
        private static weak var selectedWrapper : DebuggingWrapper? = nil {
            didSet {
                if let wrapper = self.selectedWrapper, self.selectedWrapper === oldValue {
                    let nav = UINavigationController(rootViewController: DebuggingPreviewViewController(element: wrapper.elementInfo.element))
                    
                    let host = wrapper.window?.rootViewController?.viewControllerToPresentOn
                    
                    host?.present(nav, animated: true)
                } else {
                    oldValue?.isSelected = false
                    self.selectedWrapper?.isSelected = true
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

extension UIView {
    func apply3DTransform() {
        
        var t = CATransform3DIdentity
        t.m34 = 1.0 / 1200.0;
        //t = CATransform3DTranslate(t, 10.0, 10.0, 0.0);
        t = CATransform3DScale(t, 0.9, 0.9, 0.9);
        t = CATransform3DRotate(t, CGFloat(-15 * Double.pi / 180), 0.0, 1.0, 0.0);
        t = CATransform3DRotate(t, CGFloat(-15 * Double.pi / 180), 1.0, 0.0, 0.0);

        self.layer.sublayerTransform = t
        
        self.apply3DTransformTranslation(depth: 1)
    }
    
    func apply3DTransformTranslation(depth : Int) {
        
        self.layer.zPosition = CGFloat(depth) * 10.0
                        
        for view in self.subviews {
            view.apply3DTransformTranslation(depth: depth + 1)
        }
    }
}


final class DebuggingPreviewViewController : UIViewController {
    
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
        
        self.blueprintView.element = PreviewElement(presenting: self.element)
        self.blueprintView.layoutIfNeeded()
    }
    
    struct PreviewElement : ProxyElement {
        var presenting : Element
        
        var elementRepresentation: Element {
            Box(
                backgroundColor: UIColor(white: 0.90, alpha: 1.0),
                wrapping: ScrollView(wrapping: Content(presenting: self.presenting)) {
                    $0.contentSize = .fittingHeight
                    $0.contentInset = .init(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
                }
            )
        }
        
        struct Content : ProxyElement {
            var presenting : Element
            
            var elementRepresentation: Element {
                Column {
                    $0.horizontalAlignment = .fill
                    $0.minimumVerticalSpacing = 10.0
                    
                    $0.add(child: Header(text: "Preview"))
                    $0.add(child: FloatingBox(wrapping: Preview(presenting: self.presenting)))
                    
                    $0.add(child: Header(text: "3D Visualization"))
                    $0.add(child: FloatingBox(wrapping: ThreeDVisualization(presenting: self.presenting)))
                    
                    $0.add(child: Header(text: "Hierarchy"))
                    $0.add(child: FloatingBox(wrapping: ElementInfo(presenting: self.presenting)))
                }
            }
            
            struct Header : ProxyElement {
                var text : String
                
                var elementRepresentation: Element {
                    Label(text: self.text) {
                        $0.font = .systemFont(ofSize: 32.0, weight: .bold)
                    }
                }
            }
            
            struct Preview : ProxyElement {
                var presenting : Element
                
                var elementRepresentation: Element {
                    ConstrainedSize(
                        height: .atLeast(100.0),
                        wrapping: Centered(Box(wrapping: self.presenting) {
                            $0.borderStyle = .solid(color: UIColor(white: 0.0, alpha: 0.15), width: 1.0)
                            $0.cornerStyle = .rounded(radius: 2.0)
                        })
                    )
                }
            }
            
            struct ThreeDVisualization : ProxyElement {
                var presenting : Element
                
                var elementRepresentation: Element {
                    let snapshot = FlattenedElementSnapshot(element: self.presenting, sizeConstraint: SizeConstraint(UIScreen.main.bounds.size))
                    
                    return Centered(ThreeDElementVisualization(snapshot: snapshot))
                }
            }
            
            struct ElementInfo : ProxyElement {
                var presenting : Element
                
                var elementRepresentation: Element {
                    Column {
                        $0.horizontalAlignment = .fill
                        $0.minimumVerticalSpacing = 10.0
                        
                        let list = self.presenting.recursiveElementList()
                        
                        for element in list {
                            $0.add(child: ElementRow(element: element))
                        }
                    }
                }
                
                struct ElementRow : ProxyElement {
                    fileprivate var element : RecursedElement

                    var elementRepresentation: Element {
                        Row {
                            $0.verticalAlignment = .fill
                            $0.horizontalUnderflow = .growUniformly
                            
                            let spacer = Spacer(size: CGSize(width: CGFloat(element.depth) * 15.0, height: 0.0))
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
                                let elementType = String(describing: type(of:element.element))
                                    
                                $0.add(child: Label(text: elementType) {
                                    $0.font = .systemFont(ofSize: 18.0, weight: .semibold)
                                    $0.color = .systemBlue
                                })
                                
                                $0.add(child: Spacer(size: CGSize(width: 0.0, height: 5.0)))
                                
                                $0.add(child: Box(backgroundColor: .white, wrapping: element.element))
                            }
                            
                            $0.add(
                                child: Inset(uniformInset: 5.0, wrapping: elementInfo)
                            )
                        }
                    }
                }
            }
            
            struct FloatingBox : ProxyElement {
                var wrapping : Element
                
                var elementRepresentation: Element {
                    Box(
                        wrapping: Inset(
                            uniformInset: 10.0,
                            wrapping: self.wrapping
                            )
                        ) { box in
                            box.shadowStyle = .simple(
                                radius: 4.0,
                                opacity: 0.25,
                                offset: CGSize(width: 0.0, height: 1.0),
                                color: .black
                            )
                    
                            box.cornerStyle = .rounded(radius: 10.0)
                            box.backgroundColor = .white
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
        ElementContent { _ in
            // TODO...
            return CGSize(width: self.snapshot.size.width, height: self.snapshot.size.height * 2)
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
        let snapshot : FlattenedElementSnapshot
        
        init(snapshot : FlattenedElementSnapshot) {
            self.snapshot = snapshot
            
            super.init(frame: CGRect(origin: .zero, size: self.snapshot.size))
            
            for view in snapshot.flatHierarchySnapshot {
                self.addSubview(view.view)
                view.view.frame = view.frame
                view.view.layer.zPosition = 10 * CGFloat(view.hierarchyDepth)
            }
            
            var t = CATransform3DIdentity
            // https://stackoverflow.com/questions/3881446/meaning-of-m34-of-catransform3d
            t.m34 = -1.0 / 1000.0;
            t = CATransform3DScale(t, 1.5, 1.5, 1.5);
            t = CATransform3DTranslate(t, 0.0, 50, 0.0)
            //t = CATransform3DRotate(t, CGFloat(45 * Double.pi / 180), 0.0, 1.0, 0.0);
            t = CATransform3DRotate(t, CGFloat(45 * Double.pi / 180), 1.0, 0.0, 0.0);

            self.layer.sublayerTransform = t
        }
        
        required init?(coder: NSCoder) { fatalError() }
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


extension Notification.Name {
    static var BlueprintGlobalDebuggingSettingsChanged = Notification.Name("BlueprintGlobalDebuggingSettingsChanged")
}
