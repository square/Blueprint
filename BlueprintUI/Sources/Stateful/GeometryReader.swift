//
//  GeometryReader.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 4/17/20.
//

import Foundation


public struct GeometryReader : Element {
    
    public typealias Provider = (SizeConstraint) -> Element
    
    public var provider : Provider
    
    public init(element : @escaping Provider) {
        self.provider = element
    }
    
    public var content : ElementContent {
                
        ElementContent {
            let element = self.provider($0)
            
            return element.content.measure(in: $0)
        }
    }
    
    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        ViewDescription(View.self) {
            $0.builder = {
                View(frame: bounds, provider: self.provider)
            }
        }
    }
    
    private final class View : UIView {
        
        let provider : Provider
        
        let view : BlueprintView
                
        init(frame: CGRect, provider : @escaping Provider) {
            
            self.provider = provider
            
            self.view = BlueprintView(frame: CGRect(origin: .zero, size: frame.size))
                        
            super.init(frame: frame)
            
            self.addSubview(self.view)
            
            self.updateElement(with: frame.size)
        }
        
        required init?(coder: NSCoder) { fatalError() }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            self.view.frame = self.bounds
            
            self.updateElement(with: self.bounds.size)
        }
        
        private var lastSize : CGSize = .zero
        
        private func updateElement(with size : CGSize, updateParentBlueprintViews updateParents : Bool = false) {
            
            guard size != lastSize else {
                return
            }
            
            self.lastSize = size
            
            self.view.element = self.provider(SizeConstraint(self.lastSize))
            
            if updateParents {
                var superview : UIView? = self.superview
                
                while superview != nil {
                    if let blueprintView = superview as? BlueprintView {
                        blueprintView.setNeedsViewHierarchyUpdate()
                    }
                    
                    superview = superview?.superview
                }
            }
        }
    }
}
