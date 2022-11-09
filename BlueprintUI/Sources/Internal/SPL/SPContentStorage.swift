import CoreGraphics
import Foundation


protocol SPContentStorage {
    func sizeThatFits(
        proposal: ProposedViewSize,
        context: MeasureContext
    ) -> CGSize

    func performSinglePassLayout(
        proposal: ProposedViewSize,
        context: SPLayoutContext
    ) -> [IdentifiedNode]
}
