import Foundation

/// Content storage that supports layout and multiple children.
struct LayoutStorage<LayoutType: Layout>: ContentStorage {

    typealias IdentifiedNode = ElementContent.IdentifiedNode

    var layout: LayoutType
    var children: [Child]

    init(layout: LayoutType, children: [Child]) {
        self.layout = layout
        self.children = children
    }

    struct Child {
        var traits: LayoutType.Traits
        var key: AnyHashable?
        var content: ElementContent
        var element: Element
    }
}

extension LayoutStorage: LegacyContentStorage {

    var childCount: Int {
        children.count
    }

    func measure(
        in constraint: SizeConstraint,
        environment: Environment,
        cache: CacheTree
    ) -> CGSize {
        cache.get(constraint) { constraint -> CGSize in
            Logger.logMeasureStart(
                object: cache.signpostRef,
                description: cache.name,
                constraint: constraint
            )
            defer { Logger.logMeasureEnd(object: cache.signpostRef) }

            let layoutItems = self.layoutItems(in: environment, cache: cache)
            return layout.measure(in: constraint, items: layoutItems)
        }
    }

    func performLegacyLayout(
        attributes: LayoutAttributes,
        environment: Environment,
        cache: CacheTree
    ) -> [IdentifiedNode] {
        guard children.isEmpty == false else {
            return []
        }

        let layoutItems = layoutItems(in: environment, cache: cache)
        let childAttributes = layout.layout(size: attributes.bounds.size, items: layoutItems)

        var result: [IdentifiedNode] = []
        result.reserveCapacity(children.count)

        var identifierFactory = ElementIdentifier.Factory(elementCount: children.count)

        for index in 0..<children.count {
            let currentChildLayoutAttributes = childAttributes[index]
            let currentChild = children[index]
            let currentChildCache = cache.subcache(
                index: index,
                of: children.count,
                element: currentChild.element
            )

            let resultNode = LayoutResultNode(
                element: currentChild.element,
                layoutAttributes: currentChildLayoutAttributes,
                environment: environment,
                children: currentChild.content.performLegacyLayout(
                    attributes: currentChildLayoutAttributes,
                    environment: environment,
                    cache: currentChildCache
                )
            )

            let identifier = identifierFactory.nextIdentifier(
                for: type(of: currentChild.element),
                key: currentChild.key
            )

            result.append((identifier: identifier, node: resultNode))
        }

        return result
    }

    private func layoutItems(
        in environment: Environment,
        cache: CacheTree
    ) -> [(LayoutType.Traits, Measurable)] {

        /// **Note**: We are intentionally using our `indexedMap(...)` and not `enumerated().map(...)`
        /// here; because the enumerated version is about 25% slower. Because this
        /// is an extremely hot codepath; this additional performance matters, so we will
        /// keep track of the index ourselves.

        children.indexedMap { index, child in
            let childContent = child.content
            let childCache = cache.subcache(
                index: index,
                of: children.count,
                element: child.element
            )
            let measurable = Measurer { constraint -> CGSize in
                childContent.measure(
                    in: constraint,
                    environment: environment,
                    cache: childCache
                )
            }

            return (child.traits, measurable)
        }
    }
}

extension LayoutStorage: CaffeinatedContentStorage {

    private func subelements(from node: LayoutTreeNode, environment: Environment) -> LayoutSubelements {
        var identifierFactory = ElementIdentifier.Factory(elementCount: children.count)
        return children.map { child in
            let identifier = identifierFactory.nextIdentifier(
                for: type(of: child.element),
                key: child.key
            )
            return LayoutSubelement(
                identifier: identifier,
                content: child.content,
                environment: environment,
                node: node.subnode(key: identifier),
                traits: child.traits
            )
        }
    }

    func sizeThatFits(
        proposal: SizeConstraint,
        environment: Environment,
        node: LayoutTreeNode
    ) -> CGSize {

        let subelements = subelements(from: node, environment: environment)

        var associatedCache = node.associatedCache {
            layout.makeCache(subelements: subelements, environment: environment)
        }

        let size = layout.sizeThatFits(
            proposal: proposal,
            subelements: subelements,
            environment: environment,
            cache: &associatedCache
        )

        node.update(associatedCache: associatedCache)

        return size
    }

    func performCaffeinatedLayout(
        frame: CGRect,
        environment: Environment,
        node: LayoutTreeNode
    ) -> [IdentifiedNode] {
        guard !children.isEmpty else { return [] }

        let subelements = subelements(from: node, environment: environment)

        var associatedCache = node.associatedCache {
            layout.makeCache(subelements: subelements, environment: environment)
        }

        layout.placeSubelements(
            in: frame.size,
            subelements: subelements,
            environment: environment,
            cache: &associatedCache
        )

        node.update(associatedCache: associatedCache)

        let identifiedNodes: [IdentifiedNode] = children.indexedMap { index, child in
            let subelement = subelements[index]

            let placement = subelement.placement ?? .filling(size: frame.size)

            let size = placement.size
            let origin = placement.origin(for: size)
            let frame = CGRect(origin: origin, size: size)

            let childAttributes = LayoutAttributes(
                frame: frame,
                attributes: subelement.attributes
            )

            let identifier = subelement.identifier
            let subnode = node.subnode(key: identifier)

            let node = LayoutResultNode(
                element: child.element,
                layoutAttributes: childAttributes,
                environment: environment,
                children: child.content.performCaffeinatedLayout(
                    frame: frame,
                    environment: environment,
                    node: subnode
                )
            )
            return (identifier: identifier, node: node)
        }
        return identifiedNodes
    }
}
