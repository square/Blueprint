extension EqualStack {
    /// Initializer using result builder to declaritively build up a stack.
    /// - Parameters:
    ///   - direction: Direction of the stack.
    ///   - children: A block containing all elements to be included in the stack.
    public init(
        direction: Direction,
        @Builder<Element> elements: () -> [Element],
        configure: (inout Self) -> Void = { _ in }
    ) {
        self.init(direction: direction)
        self.children = elements()
        configure(&self)
    }
}
