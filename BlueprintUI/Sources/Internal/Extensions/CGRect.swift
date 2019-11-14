import UIKit

extension CGRect {
    
    // localOriginInScreenSpace defines the origin, in screen space, of the coordinate space that this
    // rectangle exists within.
    mutating func roundedToPixelBoundaries(screenScale: CGFloat, localOriginInScreenSpace: CGPoint) -> CGRect {
        let screenSpaceRect = CGRect(
            minX: minX + localOriginInScreenSpace.x,
            minY: minY + localOriginInScreenSpace.y,
            maxX: maxX + localOriginInScreenSpace.x,
            maxY: maxY + localOriginInScreenSpace.y)
            .rounded(toScale: screenScale)
        
        return CGRect(
            minX: screenSpaceRect.minX - localOriginInScreenSpace.x,
            minY: screenSpaceRect.minY - localOriginInScreenSpace.y,
            maxX: screenSpaceRect.maxX - localOriginInScreenSpace.x,
            maxY: screenSpaceRect.maxY - localOriginInScreenSpace.y)
    }
    
    private init(minX: CGFloat, minY: CGFloat, maxX: CGFloat, maxY: CGFloat) {
        self.init(
            x: minX,
            y: minY,
            width: maxX - minX,
            height: maxY - minY)
    }

    private func rounded(toScale scale: CGFloat) -> CGRect {
        return CGRect(
            minX: minX.rounded(.toNearestOrAwayFromZero, by: scale),
            minY: minY.rounded(.toNearestOrAwayFromZero, by: scale),
            maxX: maxX.rounded(.toNearestOrAwayFromZero, by: scale),
            maxY: maxY.rounded(.toNearestOrAwayFromZero, by: scale))
    }
    
}

extension CGFloat {
    
    fileprivate func rounded(_ rule: FloatingPointRoundingRule, by scale: Self) -> Self {
        return (self * scale).rounded(rule) / scale
    }
    
}
