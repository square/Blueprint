import CoreGraphics

/// Content storage that defers creation of its child until measurement or layout time.
struct LazyStorage: ContentStorage {

    typealias IdentifiedNode = ElementContent.IdentifiedNode

    let childCount = 1

    var builder: (ElementContent.LayoutPhase, SizeConstraint, Environment) -> Element

    private func buildChild(
        for phase: ElementContent.LayoutPhase,
        in constraint: SizeConstraint,
        environment: Environment
    ) -> Element {
        builder(phase, constraint, environment)
    }
}

extension LazyStorage: CaffeinatedContentStorage {

    func sizeThatFits(
        proposal: SizeConstraint,
        environment: Environment,
        node: LayoutTreeNode,
        cache: CrossLayoutSizeCache?
    ) -> CGSize {
        let child = buildChild(
            for: .measurement,
            in: proposal,
            environment: environment
        )
        let identifier = ElementIdentifier(elementType: type(of: child), key: nil, count: 1)
        let subnode = node.subnode(key: identifier)

        return child.content.sizeThatFits(
            proposal: proposal,
            environment: environment,
            node: subnode,
            cache: cache
        )
    }

    func performCaffeinatedLayout(
        frame: CGRect,
        environment: Environment,
        node: LayoutTreeNode
    ) -> [IdentifiedNode] {
        let child = buildChild(
            for: .layout,
            in: SizeConstraint(frame.size),
            environment: environment
        )

        let childAttributes = LayoutAttributes(size: frame.size)
        let identifier = ElementIdentifier(elementType: type(of: child), key: nil, count: 1)
        let subnode = node.subnode(key: identifier)

        let node = LayoutResultNode(
            element: child,
            layoutAttributes: childAttributes,
            environment: environment,
            children: child.content.performCaffeinatedLayout(
                frame: frame,
                environment: environment,
                node: subnode
            )
        )

        return [(identifier, node)]
    }
}
