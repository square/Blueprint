import CoreGraphics
import UIKit


public protocol SPLayout {

    typealias Subviews = LayoutSubviews

    func sizeThatFits(
        proposal: SizeConstraint,
        subviews: Subviews
    ) -> CGSize

    func placeSubviews(
        in bounds: CGRect,
        proposal: SizeConstraint,
        subviews: Subviews
    )
}
