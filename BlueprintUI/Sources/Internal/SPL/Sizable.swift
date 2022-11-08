import CoreGraphics
import Foundation


protocol Sizable {

    func sizeThatFits(proposal: ProposedViewSize, context: MeasureContext) -> CGSize
}
