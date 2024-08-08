import UIKit


extension UIBezierPath {

    public convenience init(
        rect: CGRect,
        corners: CornerStyle
    ) {
        switch corners {
        case .square:
            self.init(rect: rect)
        case .capsule:

            let radius = rect.size.height / 2

            self.init(
                roundedRect: rect,
                byRoundingCorners: .allCorners,
                cornerRadii: CGSize(width: radius, height: radius)
            )
        case .rounded(let radius, let corners):
            self.init(
                roundedRect: rect,
                byRoundingCorners: corners.toUIRectCorner,
                cornerRadii: CGSize(width: radius, height: radius)
            )
        }
    }
}
