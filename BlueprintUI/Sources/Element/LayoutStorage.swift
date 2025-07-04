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

    var childCount: Int {
        children.count
    }

    struct Child {
        var traits: LayoutTraits
        var key: AnyHashable?
        var content: ElementContent
        var element: Element

        init(
            traits: LayoutTraits = .empty,
            key: AnyHashable? = nil,
            content: ElementContent,
            element: Element
        ) {
            self.traits = traits
            self.key = key
            self.content = content
            self.element = element
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
