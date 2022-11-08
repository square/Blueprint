import CoreGraphics
import Foundation


public protocol SPSingleChildLayout {

    func sizeThatFits(proposal: ProposedViewSize, subview: LayoutSubview) -> CGSize

    func placeSubview(in bounds: CGRect, proposal: ProposedViewSize, subview: LayoutSubview)
}
