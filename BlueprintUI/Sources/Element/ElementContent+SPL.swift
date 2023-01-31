import Foundation


extension ElementContent: Sizable {

    func sizeThatFits(proposal: SizeConstraint, context: MeasureContext) -> CGSize {
        storage.sizeThatFits(proposal: proposal, context: context)
    }
}


extension ElementContent.Builder {
    
    private func subviews(from cache: SPCacheNode, environment: Environment) -> LayoutSubviews {

        cache.layoutSubviews {
            var identifierFactory = ElementIdentifier.Factory(elementCount: children.count)
            return children.map { child in
                let identifier = identifierFactory.nextIdentifier(
                    for: type(of: child.element),
                    key: child.key
                )
                return LayoutSubview(
                    identifier: identifier,
                    element: child.element,
                    content: child.content,
                    measureContext: .init(
                        cache: cache.subcache(key: identifier),
                        environment: environment
                    ),
                    traits: child.traits,
                    layoutType: LayoutType.self
                )
            }
        }
    }

    func sizeThatFits(proposal: SizeConstraint, context: MeasureContext) -> CGSize {
        
        let subviews = subviews(from: context.cache, environment: context.environment)
        
        var phaseCache = context.cache.phaseCache(create: { layout.makeCache(subviews: subviews) })
        
        let size = layout.sizeThatFits(proposal: proposal, subviews: subviews, cache: &phaseCache)
        
        context.cache.set(phaseCache: phaseCache)
        
        return size
    }

    func performSinglePassLayout(proposal: SizeConstraint, context: SPLayoutContext) -> [IdentifiedNode] {
        guard children.isEmpty == false else { return [] }

        let subviews = subviews(from: context.cache, environment: context.environment)

        let attributes = context.attributes
        let frame = context.attributes.frame

        var phaseCache = context.cache.phaseCache(create: { layout.makeCache(subviews: subviews) })

        layout.placeSubviews(
            in: frame,
            proposal: proposal,
            subviews: subviews,
            cache: &phaseCache
        )

        context.cache.set(phaseCache: phaseCache)

        let identifiedNodes: [IdentifiedNode] = children.indexedMap { index, child in
            let subview = subviews[index]

            let placement = subview.placement
                ?? .filling(frame: attributes.frame, proposal: proposal)

            let size: CGSize
            if let width = placement.size.width, let height = placement.size.height {
                size = .init(width: width, height: height)
            } else {
                let measuredSize = subview.sizeThatFits(placement.size.proposal)
                size = .init(
                    width: placement.size.width ?? measuredSize.width,
                    height: placement.size.height ?? measuredSize.height
                )
            }
            let childOrigin = placement.origin(for: size)

            let offsetFrame = CGRect(
                origin: childOrigin - frame.origin,
                size: size
            )

            let childAttributes = LayoutAttributes(
                frame: offsetFrame,
                attributes: subview.attributes
            )

            let identifier = subview.identifier

            let childContext = SPLayoutContext(
                attributes: childAttributes,
                environment: context.environment,
                cache: context.cache.subcache(key: identifier)
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
