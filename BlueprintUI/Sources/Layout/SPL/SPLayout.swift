import CoreGraphics
import UIKit


public protocol SPLayout {

    typealias Subviews = LayoutSubviews

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews
    ) -> CGSize

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews
    )
}
