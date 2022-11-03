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

public enum GenericLayoutValueKey<LayoutType: Layout>: LayoutValueKey {
    public static var defaultValue: LayoutType.Traits {
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

    var valueCache: SPValueCache<Key, Value>
    private var subcaches: [SubcacheKey: Subcache] = [:]

    var path: String

    init(path: String? = nil) {
        let path = path ?? ""
        self.path = path
        valueCache = .init(path: path)
    }

    func get(key: Key, or create: (Key) -> Value) -> Value {
        valueCache.get(key: key, or: create)
    }

    func subcache(key: SubcacheKey) -> Subcache {
        if let subcache = subcaches[key] {
            return subcache
        }
        let subcache = Subcache(path: path + "/" + String(describing: key))
        subcaches[key] = subcache
        return subcache
    }
}

final class SPValueCache<Key: Hashable, Value> {
    var values: [Key: Value] = [:]

    var path: String

    init(path: String) {
        self.path = path
    }

    func get(key: Key, or create: (Key) -> Value) -> Value {
        if let size = values[key] {
            print("XXX Hit at  \(path.padding(toLength: 8, withPad: " ", startingAt: 0))): \t\(String(describing: key).padding(toLength: 16, withPad: " ", startingAt: 0)) \t-> \t\(size)")
            return size
        }
        let size = create(key)
        print("OOO Miss at \(path.padding(toLength: 8, withPad: " ", startingAt: 0)): \t\(String(describing: key).padding(toLength: 16, withPad: " ", startingAt: 0)) \t-> \t\(size)")
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
        guard children.isEmpty == false else { return [] }

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
                ?? .filling(frame: attributes.frame, proposal: proposal)

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

            let offsetFrame = CGRect(
                origin: childOrigin - frame.origin,
                size: size
            )
//            print("\(type(of: subview.element)) frame \(childFrame) within \(frame)")

            let childAttributes = LayoutAttributes(
                frame: offsetFrame,
                attributes: subview.attributes
            )

            let identifier = identifierFactory.nextIdentifier(
                for: type(of: subview.element),
                key: child.key
            )

            let childContext = SPLayoutContext(
                attributes: childAttributes,
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
//            print("\(type(of: child.element)) result \(node.layoutAttributes.frame)")
            return (identifier: identifier, node: node)
        }
        return identifiedNodes
    }
}


extension LayoutAttributes {

    init(frame: CGRect, attributes: LayoutSubview.Attributes) {
        var layoutAttributes = LayoutAttributes(frame: frame)
        layoutAttributes.transform = attributes.transform
        layoutAttributes.alpha = attributes.alpha
        layoutAttributes.isUserInteractionEnabled = attributes.isUserInteractionEnabled
        layoutAttributes.isHidden = attributes.isHidden
        self = layoutAttributes
    }
}

enum DebugScopeKey: EnvironmentKey {
    static let defaultValue: [String] = []
}

extension Element {
    public func debugScope(_ scope: String) -> Element {
        adaptedEnvironment { environment in
            environment[DebugScopeKey.self].append(scope)
        }
    }
}
