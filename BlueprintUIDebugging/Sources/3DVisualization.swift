//
//  3DVisualization.swift
//  BlueprintUIDebugging
//
//  Created by Kyle Van Essen on 4/24/20.
//

import UIKit
import BlueprintUI
import BlueprintUICommonControls


struct ThreeDElementVisualization : Element {
    
    // TODO: This holds onto live views... need to not hold onto but generate internal to the view.
    var snapshot : FlattenedElementViewHierarchy
    
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
        private let snapshot : FlattenedElementViewHierarchy
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
        
        init(snapshot : FlattenedElementViewHierarchy) {
            
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
            private let snapshot : FlattenedElementViewHierarchy
            
            init(snapshot : FlattenedElementViewHierarchy) {
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

