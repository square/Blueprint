import CoreGraphics

/// The implementation of an `ElementContent`.
protocol ContentStorage: CaffeinatedContentStorage {
    var childCount: Int { get }
}

protocol CaffeinatedContentStorage {
    func sizeThatFits(
        proposal: SizeConstraint,
        environment: Environment,
        node: LayoutTreeNode
    ) -> CGSize

    func performCaffeinatedLayout(
        frame: CGRect,
        environment: Environment,
        node: LayoutTreeNode
    ) -> [ElementContent.IdentifiedNode]

    func adapt(
        _ environment: inout Environment,
        for node: LayoutTreeNode
    )
}


extension CaffeinatedContentStorage {

    func adapt(
        _ environment: inout Environment,
        for node: LayoutTreeNode
    ) {
        // Nothin
    }
}
