/// Wraps around an Element for consistency with `StackChild` and `GridRowChild`.
/// In the future this struct could hold traits used for laying out inside an EqualStack
extension EqualStack {
    public struct Child {
        public let element: Element

        public init(element: Element) {
            self.element = element
        }
    }
}

extension EqualStack.Child: ElementBuilderChild {
    public init(from element: Element) {
        self.init(element: element)
    }
}
