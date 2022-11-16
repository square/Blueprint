import CoreGraphics
import UIKit


public protocol SPLayout {

    typealias Subviews = LayoutSubviews

    associatedtype Cache = Void

    func sizeThatFits(
        proposal: SizeConstraint,
        subviews: Subviews,
        cache: inout Self.Cache
    ) -> CGSize

    func placeSubviews(
        in bounds: CGRect,
        proposal: SizeConstraint,
        subviews: Subviews,
        cache: inout Self.Cache
    )

    func makeCache(subviews: Subviews) -> Cache
}


extension SPLayout where Cache == Void {

    public func makeCache(subviews: Subviews) { () }
}
