import CoreGraphics
import Foundation


protocol SPContentStorage {
    func sizeThatFits(
        proposal: SizeConstraint,
        context: MeasureContext
    ) -> CGSize

    func performSinglePassLayout(
        proposal: SizeConstraint,
        context: SPLayoutContext
    ) -> [IdentifiedNode]
}
