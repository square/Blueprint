//
//  FrameReader.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 1/13/21.
//

import UIKit


public struct FrameReader : Element {
    
    public var wrapped : Element
    
    public var isActive : Bool
    
    public typealias OnChange = (UICoordinateSpace) -> ()
    
    public var onChange : OnChange
    
    init(
        wrapping element : Element,
        isActive : Bool,
        onChange : @escaping OnChange
    ) {
        self.wrapped = element
        self.isActive = isActive
        self.onChange = onChange
    }
    
    public var content: ElementContent {
        ElementContent(child: self.wrapped)
    }
    
    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        View.describe { config in
            
            config.builder = {
                View(
                    frame: bounds,
                    isActive: self.isActive,
                    onChange: self.onChange
                )
            }
            
            config.apply {
                $0.isActive = self.isActive
                $0.onChange = self.onChange
                
                $0.updateDisplayLinkState()
            }
        }
    }
}


extension FrameReader {
    
    public func readFrame(
        isActive : Bool,
        onChange : @escaping OnChange
    ) -> Self {
        FrameReader(
            wrapping: self,
            isActive: isActive,
            onChange: onChange
        )
    }
}


extension FrameReader {
        
    private final class View : UIView {
        
        var onChange : OnChange
        var isActive : Bool
        
        private var state : State
        
        private enum State {
            case notTracking
            case tracking(CADisplayLink)
            
            var isTracking : Bool {
                switch self {
                case .notTracking: return false
                case .tracking(_): return true
                }
            }
            
            func stop() {
                switch self {
                case .notTracking: break
                case .tracking(let link): link.invalidate()
                }
            }
        }
        
        init(frame: CGRect, isActive : Bool, onChange : @escaping OnChange) {
            
            self.state = .notTracking
            
            self.isActive = isActive
            self.onChange = onChange
            
            super.init(frame: frame)
        }
        
        deinit {
            self.state.stop()
        }
        
        required init?(coder: NSCoder) { fatalError() }
        
        override func didMoveToWindow() {
            super.didMoveToSuperview()
            
            self.updateDisplayLinkState()
        }
        
        override func didMoveToSuperview() {
            super.didMoveToSuperview()
            
            self.updateDisplayLinkState()
        }
        
        override var isHidden: Bool {
            didSet {
                self.updateDisplayLinkState()
            }
        }
        
        private var lastPosition : CGRect? = nil
        
        private func displayLinkFired() {
            
            let position = self.convert(self.bounds, to: nil)
            
            guard self.lastPosition != position else {
                return
            }
            
            self.lastPosition = position
            
            self.onChange(self)
        }
        
        fileprivate func updateDisplayLinkState() {
            let shouldTrack = self.isActive && self.window != nil && self.superview != nil && self.isHidden == false
            
            switch self.state {
            case .notTracking:
                if shouldTrack {
                    let target = Target(self)
                    let displayLink = CADisplayLink(target: target, selector: #selector(Target.displayLinkFired(_:)))
                    self.state = .tracking(displayLink)
                }
                
            case .tracking(let displayLink):
                if shouldTrack == false {
                    displayLink.invalidate()
                    self.state = .notTracking
                }
            }
        }
        
        private final class Target : NSObject {
            weak var view : View?
            
            init(_ view : View) {
                self.view = view
            }
            
            @objc fileprivate func displayLinkFired(_ link : CADisplayLink) {
                self.view?.displayLinkFired()
            }
        }
    }
}

