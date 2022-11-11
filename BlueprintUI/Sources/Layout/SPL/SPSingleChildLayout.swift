import CoreGraphics
import Foundation


public protocol SPSingleChildLayout {

    func sizeThatFits(proposal: SizeConstraint, subview: LayoutSubview) -> CGSize

    func placeSubview(in bounds: CGRect, proposal: SizeConstraint, subview: LayoutSubview)
}
