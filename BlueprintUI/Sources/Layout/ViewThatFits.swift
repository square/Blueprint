import UIKit


public struct ViewThatFits: ProxyElement {

    public var direction: GeometryProxy.Direction

    public var elements: [Element]

    public init(
        _ direction: GeometryProxy.Direction = .horizontal,
        @Builder<Element> elements: () -> [Element]
    ) {
        self.direction = direction
        self.elements = elements()
    }

    // TODO: Respect direction

    public var elementRepresentation: Element {
        GeometryReader { proxy in

            for element in elements {
                if proxy.ifFits(width: proxy.constraint.width, element: { element }) {
                    return element
                }
            }

            /// Nothing fit, so return the last element – per API guidelines, this should generally be the smallest element.

            return elements.last ?? Empty()
        }
    }
}

