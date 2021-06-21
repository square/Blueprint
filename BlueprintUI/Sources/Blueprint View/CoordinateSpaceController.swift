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
        
        var onChange : CoordinateSpaceTracking.Callback
        
        let view : UIView
        weak var blueprintView : BlueprintView?
        
        init(
            with view : UIView,
            in blueprintView : BlueprintView,
            onChange : @escaping CoordinateSpaceTracking.Callback
        ) {
            self.view = view
            self.blueprintView = blueprintView
            self.onChange = onChange
        }
        
        deinit {
            self.displayLink?.invalidate()
        }
        
        private var displayLink : CADisplayLink?
        
        func start() {
            guard self.displayLink == nil else {
                fatalError()
            }
            
            self.displayLink = CADisplayLink(target: self, selector: #selector(onDisplayLinkFired))
            
            self.displayLink?.add(to: .current, forMode: .common)
        }
        
        func stop() {
            self.displayLink?.invalidate()
            self.displayLink = nil
        }
        
        private var lastCoordinateSpaceFrame : CGRect? = nil
        
        func sendOnCoordinateSpaceChangedIfNeeded() {
            
            guard let blueprintView = self.blueprintView else {
                return
            }
            
            guard let parent = self.findHighestParent(for: self.view) else {
                return
            }
            
            let frame = self.view.convert(view.bounds, to: parent)
            
            if self.lastCoordinateSpaceFrame != frame {
                self.lastCoordinateSpaceFrame = frame
                self.onChange(
                    .init(
                        element: view,
                        blueprintView: blueprintView,
                        top: parent
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
