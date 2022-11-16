import CoreGraphics
import Foundation


public protocol SPSingleChildLayout {

    associatedtype Cache = Void

    func sizeThatFits(proposal: SizeConstraint, subview: LayoutSubview, cache: inout Cache) -> CGSize

    func placeSubview(in bounds: CGRect, proposal: SizeConstraint, subview: LayoutSubview, cache: inout Cache)

    func makeCache(subview: LayoutSubview) -> Cache
}


extension SPSingleChildLayout where Cache == Void {

    public func makeCache(subview: LayoutSubview) { () }
}
