import Foundation

typealias IdentifiedNode = (identifier: ElementIdentifier, node: LayoutResultNode)

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

enum GenericLayoutValueKey<LayoutType: Layout>: LayoutValueKey {
    static var defaultValue: LayoutType.Traits {
        LayoutType.defaultTraits
    }
}

extension ElementContent: Sizable {
    func sizeThatFits(proposal: ProposedViewSize, context: MeasureContext) -> CGSize {
        storage.sizeThatFits(proposal: proposal, context: context)
    }
}

final class SPCacheTree<Key, Value, SubcacheKey> where Key: Hashable, SubcacheKey: Hashable {
    typealias Subcache = SPCacheTree<Key, Value, SubcacheKey>

    var valueCache: SPValueCache<Key, Value> = .init()
    private var subcaches: [SubcacheKey: Subcache] = [:]

    func get(key: Key, or create: (Key) -> Value) -> Value {
        valueCache.get(key: key, or: create)
    }

    func subcache(key: SubcacheKey) -> Subcache {
        if let subcache = subcaches[key] {
            return subcache
        }
        let subcache = Subcache()
        subcaches[key] = subcache
        return subcache
    }
}

final class SPValueCache<Key: Hashable, Value> {
    var values: [Key: Value] = [:]

    func get(key: Key, or create: (Key) -> Value) -> Value {
        if let size = values[key] {
            return size
        }
        let size = create(key)
        values[key] = size
        return size
    }
}

typealias SPCacheNode = SPCacheTree<ProposedViewSize, CGSize, Int>

struct MeasureContext {
    var cache: SPCacheNode
    var environment: Environment
}

extension ElementContent.Builder {
    func sizeThatFits(proposal: ProposedViewSize, context: MeasureContext) -> CGSize {
        let subviews = zip(children, children.indices).map { child, index in
            LayoutSubview(
                element: child.element,
                content: child.content,
                measureContext: .init(
                    cache: context.cache.subcache(key: index),
                    environment: context.environment
                ),
                key: GenericLayoutValueKey<LayoutType>.self,
                value: child.traits
            )
        }
        return layout.sizeThatFits(proposal: proposal, subviews: subviews)
    }


    func performSinglePassLayout(proposal: ProposedViewSize, context: SPLayoutContext) -> [IdentifiedNode] {

        let subviews = zip(children, children.indices).map { child, index in
            LayoutSubview(
                element: child.element,
                content: child.content,
                measureContext: .init(
                    cache: context.cache.subcache(key: index),
                    environment: context.environment
                ),
                key: GenericLayoutValueKey<LayoutType>.self,
                value: child.traits
            )
        }

        let attributes = context.attributes
        let frame = context.attributes.frame

        layout.placeSubviews(
            in: frame,
            proposal: proposal,
            subviews: subviews
        )

        var identifierFactory = ElementIdentifier.Factory(elementCount: children.count)

        let identifiedNodes: [IdentifiedNode] = children.indices.map { index in
            let child = children[index]
            let subview = subviews[index]

            let placement = subview.placement
                ?? .init(position: attributes.center, anchor: .center, size: .proposal(proposal))

            let size: CGSize
            if let width = placement.size.width, let height = placement.size.height {
                size = .init(width: width, height: height)
//                print("\(type(of: subview.element)) placed at fixed size \(size)")
            } else {
                let measuredSize = subview.sizeThatFits(placement.size.proposal)
                size = .init(
                    width: placement.size.width ?? measuredSize.width,
                    height: placement.size.height ?? measuredSize.height
                )
//                print("\(type(of: subview.element)) placed at measured \(measuredSize) and resolved to \(size)")
            }
            let childOrigin = placement.origin(for: size)

            let childFrame = CGRect(
                origin: childOrigin,
                size: size
            )
            let offsetFrame = CGRect(
                origin: childOrigin - frame.origin,
                size: size
            )
            print("\(type(of: subview.element)) frame \(childFrame) within \(frame)")

            let childAttributes = LayoutAttributes(frame: offsetFrame)
            let identifier = identifierFactory.nextIdentifier(
                for: type(of: subview.element),
                key: child.key
            )

            let childContext = SPLayoutContext(
                attributes: LayoutAttributes(frame: offsetFrame),
                environment: context.environment,
                cache: context.cache.subcache(key: index)
            )

            let node = LayoutResultNode(
                element: child.element,
                layoutAttributes: childAttributes,
                environment: context.environment,
                children: child.content.performSinglePassLayout(
                    proposal: placement.size.proposal,
                    context: childContext
                )
            )
            print("\(type(of: child.element)) result \(node.layoutAttributes.frame)")
            return (identifier: identifier, node: node)
        }
        return identifiedNodes
    }
}

