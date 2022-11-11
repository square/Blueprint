import CoreGraphics
import Foundation


protocol Sizable {

    func sizeThatFits(proposal: SizeConstraint, context: MeasureContext) -> CGSize
}
