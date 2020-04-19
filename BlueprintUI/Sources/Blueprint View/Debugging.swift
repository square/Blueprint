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
        
        let element : Element
        
        let containedView : UIView?
        
        let longPress : UILongPressGestureRecognizer
        
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
                self.layer.cornerRadius = 4.0
                
                self.layer.borderColor = UIColor.systemBlue.cgColor
            } else {
                self.layer.borderWidth = 1.0
                self.layer.cornerRadius = 2.0
                
                self.layer.borderColor = UIColor.black.withAlphaComponent(0.3).cgColor
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
            
            self.element = element
            
            self.longPress = UILongPressGestureRecognizer()
            
            super.init(frame: frame)

            if let view = self.containedView {
                self.addSubview(view)
            }
            
            self.longPress.addTarget(self, action: #selector(didLongPress))
            self.addGestureRecognizer(self.longPress)
            
            self.backgroundColor = .clear
            self.isOpaque = false
            
            self.updateIsSelected()
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            self.containedView?.frame = self.bounds
        }
        
        required init?(coder: NSCoder) { fatalError() }
        
        @objc private func didLongPress() {
            
            guard self.longPress.state == .began else {
                return
            }
            
            Self.selectedWrapper = self
        }
        
        private static weak var selectedWrapper : DebuggingWrapper? = nil {
            didSet {
                if let wrapper = self.selectedWrapper, self.selectedWrapper === oldValue {
                    let nav = UINavigationController(rootViewController: DebuggingPreviewViewController(element: wrapper.element))
                    
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
        self.blueprintView.debugging.showElementFrames = .viewBacked
        
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
            
            struct ElementInfo : ProxyElement {
                var presenting : Element
                
                var elementRepresentation: Element {
                    Column {
                        $0.horizontalAlignment = .fill
                        
                        let list = self.presenting.recursiveElementList()
                        
                        for element in list {
                            $0.add(child: Row {
                                $0.verticalAlignment = .fill
                                $0.horizontalUnderflow = .justifyToStart
                                
                                $0.add(growPriority: 0.0, shrinkPriority: 0.0, child: Spacer(size: CGSize(width: CGFloat(element.depth) * 10.0, height: 0.0)))
                                $0.add(growPriority: 0.0, shrinkPriority: 0.0, child: Rule(orientation: .vertical, color: .darkGray))
                                $0.add(growPriority: 0.0, shrinkPriority: 0.0, child: Spacer(size: CGSize(width: 5.0, height: 0.0)))
                                $0.add(growPriority: 0.0, shrinkPriority: 0.0, child: Label(text: String(describing: type(of:element.element))))
                            })
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


extension Notification.Name {
    static var BlueprintGlobalDebuggingSettingsChanged = Notification.Name("BlueprintGlobalDebuggingSettingsChanged")
}
