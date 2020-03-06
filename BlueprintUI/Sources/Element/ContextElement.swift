import CoreGraphics

public protocol ContextElement: Element {
    func elementRepresentation(in environment: Environment) -> Element
}

extension ContextElement {
    public var content: ElementContent {
        return ElementContent(build: self.elementRepresentation(in:))
    }

    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return nil
    }
}
