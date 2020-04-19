//
//  Debugging.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 4/18/20.
//

import Foundation


public struct Debugging : Equatable {
    
    public var options : Options
    
    public static var none : Debugging {
        Debugging(options: .none)
    }
    
    public var isEnabled : Bool {
        self.options.isEnabled
    }
    
    public struct Options : OptionSet, Equatable
    {
        public var rawValue : Int
        
        public static var none = Options(rawValue: 0)
        public static var all = Options(rawValue: ~0)
        
        public static var showElementFrames = Options(rawValue : 1 << 0)
        public static var longPressForDebugger = Options(rawValue : 1 << 1)
        public static var exploreElementHistory = Options(rawValue : 1 << 2)
        
        public init(rawValue : Int) {
            self.rawValue = rawValue
        }
        
        public var isEnabled : Bool {
            self != .none
        }
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
                    
                    wrapper.window?.rootViewController?.present(nav, animated: true)
                } else {
                    oldValue?.isSelected = false
                    self.selectedWrapper?.isSelected = true
                }
            }
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
                    
                    let preview = FloatingBox(
                        wrapping: ConstrainedSize(
                            height: .atLeast(100.0),
                            wrapping: Centered(self.presenting)
                        )
                    )
                        
                    $0.add(child: preview)
                }
            }
            
            struct FloatingBox : ProxyElement {
                var wrapping : Element
                
                var elementRepresentation: Element {
                    Inset(
                        bottom: 10.0,
                        wrapping: Box(
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
                    )
                }
            }
        }
    }
}


extension Notification.Name {
    static var BlueprintGlobalDebuggingSettingsChanged = Notification.Name("BlueprintGlobalDebuggingSettingsChanged")
}