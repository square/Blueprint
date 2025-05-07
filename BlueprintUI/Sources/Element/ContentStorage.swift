import CoreGraphics

extension ElementContent {

    struct ForEachElementContext {

        var state: ElementState
        var element: Element
        var layoutNode: LayoutResultNode

    }
}


/// The underlying type that backs the `ElementContent`.
/// The implementation of an `ElementContent`.
protocol ContentStorage: LegacyContentStorage, CaffeinatedContentStorage {

    var childCount: Int { get }

}

protocol LegacyContentStorage {

    func measure(
        in constraint: SizeConstraint,
        environment: Environment,
        cache: CacheTree
    ) -> CGSize

    func performLegacyLayout(
        attributes: LayoutAttributes,
        environment: Environment,
        cache: CacheTree
    ) -> [ElementContent.IdentifiedNode]
}

protocol CaffeinatedContentStorage: CaffeinatedContentStorageCrossRenderCached {

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

}

// FIXME: BETTER NAMES
protocol CaffeinatedContentStorageCrossRenderCached {

    func cachedMeasure(
        in constraint: SizeConstraint,
        with environment: Environment,
        state: ElementState
    ) -> CGSize

    func performCachedCaffeinatedLayout(
        in size: CGSize,
        with environment: Environment,
        state: ElementState
    ) -> [LayoutResultNode]

    func forEachElement(
        in size: CGSize,
        with environment: Environment,
        children childNodes: [LayoutResultNode],
        state: ElementState,
        forEach: (ElementContent.ForEachElementContext) -> Void
    )

}
