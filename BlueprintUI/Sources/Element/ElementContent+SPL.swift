import Foundation

extension ElementContent: Sizable {
    func sizeThatFits(proposal: ProposedViewSize, environment: Environment) -> CGSize {
        storage.sizeThatFits(proposal: proposal, environment: environment)
    }
}


extension ElementContent.Builder {
    func sizeThatFits(proposal: ProposedViewSize, environment: Environment) -> CGSize {
        let subviews = children.map { child in
            LayoutSubview(
                element: child.element,
                content: child.content,
                environment: environment,
                key: GenericLayoutValueKey<LayoutType>.self,
                value: child.traits
            )
        }
        return layout.sizeThatFits(proposal: proposal, subviews: subviews)
    }


    func performSinglePassLayout(context: SPLayoutContext, environment: Environment) -> [IdentifiedNode] {

//        let proposal = ProposedViewSize(attributes.bounds.size)
        let attributes = context.attributes
        let proposal = context.proposal
        let frame = context.attributes.frame

        let subviews = children.map { child in
            LayoutSubview(
                element: child.element,
                content: child.content,
                environment: environment,
                key: GenericLayoutValueKey<LayoutType>.self,
                value: child.traits
            )
        }

//        let bounds = CGRect(origin: .zero, size: attributes.bounds.size)
        layout.placeSubviews(
            in: frame,
            proposal: proposal,
            subviews: subviews
        )

        var identifierFactory = ElementIdentifier.Factory(elementCount: children.count)

        let identifiedNodes: [IdentifiedNode] = zip(children, subviews).map { child, subview in

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
                proposal: placement.size.proposal,
                attributes: LayoutAttributes(frame: offsetFrame)
            )

            let node = LayoutResultNode(
                element: child.element,
                layoutAttributes: childAttributes,
                environment: environment,
                children: child.content.performSinglePassLayout(
                    context: childContext,
                    environment: environment
                )
            )
            print("\(type(of: child.element)) result \(node.layoutAttributes.frame)")
            return (identifier: identifier, node: node)
        }
        return identifiedNodes
    }
}

