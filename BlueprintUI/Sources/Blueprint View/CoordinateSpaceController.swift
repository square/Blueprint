//
//  CoordinateSpaceController.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 6/20/21.
//

import Foundation


extension BlueprintView.NativeViewController {
    
    /// Wraps up the state management to provide a ``CADisplayLink`` for any
    /// view-backed ``Element`` whose ``ViewDescription`` that has provided a
    /// ``ViewDescription/coordinateSpaceTracking`` instance, which is then used
    /// to drive updates to consumers about when the element's on-screen position changes.
    ///
    /// The ``CoordinateSpaceController`` instance is created and managed by the
    /// ``NativeViewController``, and is updated when the element tree is updated.
    ///
    final class CoordinateSpaceController {
        
        let view : UIView
        private(set) weak var blueprintView : BlueprintView?
        
        private(set) var tracking : CoordinateSpaceTracking?
        
        init(
            with view : UIView,
            in blueprintView : BlueprintView
        ) {
            self.view = view
            self.blueprintView = blueprintView
        }
        
        deinit {
            self.displayLink?.invalidate()
        }
        
        func stop() {
            self.displayLink?.invalidate()
            self.displayLink = nil
        }
        
        private var displayLink : CADisplayLink?
        
        func apply(_ tracking : CoordinateSpaceTracking) {
            
            self.tracking = tracking
            
            if self.displayLink == nil {
                let link = CADisplayLink(target: self, selector: #selector(onDisplayLinkFired))
                link.isPaused = true
                link.add(to: .current, forMode: .common)
                
                self.displayLink = link
            }
            
            self.displayLink?.isPaused = tracking.isActive
            
        }
        
        private var lastCoordinateSpaceFrame : CGRect? = nil
        
        func sendOnCoordinateSpaceChangedIfNeeded() {
            
            guard let tracking = self.tracking else {
                return
            }
            
            guard let blueprintView = self.blueprintView else {
                return
            }
            
            guard let parent = self.findHighestParent(for: self.view) else {
                return
            }
            
            let frame = self.view.convert(view.bounds, to: parent)
            
            if self.lastCoordinateSpaceFrame != frame {
                
                self.lastCoordinateSpaceFrame = frame
                
                tracking.onChange(
                    .init(
                        element: view.coordinateSpace,
                        blueprintView: blueprintView.coordinateSpace,
                        top: parent.coordinateSpace,
                        window: view.window?.coordinateSpace
                    )
                )
            }
        }
        
        func findHighestParent(for view : UIView) -> UIView? {
            
            // Shortcut: The window is also a view, so return it.
            if let window = view.window {
                return window
            }
            
            // Otherwise, iterate our way up through the view hierarchy to find the highest superview.
            
            var parent : UIView? = view.superview
            
            while parent != nil {
                if parent?.superview != nil {
                    parent = parent?.superview
                } else {
                    return parent
                }
            }
            
            return nil
        }
        
        @objc private func onDisplayLinkFired() {
            self.sendOnCoordinateSpaceChangedIfNeeded()
        }
    }
}
