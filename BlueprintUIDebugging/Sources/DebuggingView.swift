//
//  DebuggingView.swift
//  BlueprintUIDebugging
//
//  Created by Kyle Van Essen on 4/24/20.
//

import UIKit
import BlueprintUI
import BlueprintUICommonControls


final class DebuggingView : UIView {
   
    let elementInfo : ElementInfo
    let debugging : DebuggingOptions
    
    struct ElementInfo {
        var element : Element
        var isViewBacked : Bool
    }
    
    let containedView : UIView?
    private let infoView : InfoView
    
    let tapRecognizer : UITapGestureRecognizer
    
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
    
    init(frame: CGRect, containing : ViewDescription?, for element : Element, debugging : DebuggingOptions) {
        
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
        
        self.tapRecognizer = UITapGestureRecognizer()
        
        super.init(frame: frame)

        if debugging.isIn3DPreview {
            self.addSubview(self.infoView)
        }
        
        if let view = self.containedView {
            self.addSubview(view)
        }
        
        self.tapRecognizer.addTarget(self, action: #selector(didTap))
        self.addGestureRecognizer(self.tapRecognizer)
        
        self.updateIsSelected()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.containedView?.frame = self.bounds
                    
        let size = self.infoView.sizeThatFits(self.bounds.size)
        self.infoView.frame = CGRect(x: 0.0, y: self.bounds.height + 2.0, width: size.width, height: size.height)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    @objc private func didTap() {
        
        guard self.tapRecognizer.state == .recognized else {
            return
        }
        
        let point = self.tapRecognizer.location(in: self)

        let subviews = self.views(at: point) {
            $0 is BlueprintView
        }

        let filtered : [DebuggingView] = subviews.compactMap { view in
            if let view = view as? DebuggingView {
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
    
    private static weak var selectedWrapper : DebuggingView? = nil {
        didSet {
            guard oldValue !== self.selectedWrapper else {
                return
            }
            
            oldValue?.isSelected = false
            self.selectedWrapper?.isSelected = true
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
