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
        
        var tracking : CoordinateSpaceTracking?
        
        init(
            with view : UIView,
            in blueprintView : BlueprintView
        ) {
            self.view = view
            self.blueprintView = blueprintView
        }
        
        deinit {
            self.stopTrackingIfNeeded()
        }
        
        private var state : State = .created
        
        private enum State {
            case created
            case tracking(Tracking)
            case complete
            
            struct Tracking {
                let displayLink : CADisplayLink
            }
        }
        
        func startTrackingIfNeeded() {
            guard case .created = self.state else {
                return
            }
            
            let link = CADisplayLink(target: self, selector: #selector(onDisplayLinkFired))
            link.add(to: .current, forMode: .common)
            
            self.state = .tracking(.init(displayLink: link))
            
            self.sendOnCoordinateSpaceChangedIfNeeded(to: self.tracking?.onAppear)
        }
        
        func stopTrackingIfNeeded() {
            guard case let .tracking(tracking) = self.state else {
                return
            }
            
            tracking.displayLink.invalidate()
            
            self.tracking?.onDisappear()
            
            self.state = .complete
        }
        
        private var lastCoordinateSpaceFrame : CGRect? = nil
        
        func sendOnCoordinateSpaceChangedIfNeeded(to callback : CoordinateSpaceTracking.Callback?) {
            
            guard case .tracking = self.state else {
                return
            }
            
            guard let callback = callback else {
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
                
                let context = CoordinateSpaceTracking.Context(
                    element: view.coordinateSpace,
                    blueprintView: blueprintView.coordinateSpace,
                    top: parent.coordinateSpace,
                    window: view.window?.coordinateSpace
                )
                
                callback(context)
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
            self.sendOnCoordinateSpaceChangedIfNeeded(to: self.tracking?.onChange)
        }
    }
}
