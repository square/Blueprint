/// Generic result builder for converting blocks of `Child...` into `[Child]`.
@_functionBuilder // change to @resultBuilder when we upgrade to Swift 5.4.
public struct ElementBuilder<T: ElementInitializable> {
    public typealias Component = [T]

    public static func buildBlock(_ elements: Component...) -> Component {
        elements.flatMap { $0 }
    }

    public static func buildOptional(_ elements: Component?) -> Component {
        elements ?? []
    }

    public static func buildEither(first: Component) -> Component {
        first
    }

    public static func buildEither(second: Component) -> Component {
        second
    }
    
    public static func buildExpression(_ element: T) -> Component {
        [element]
    }
    
    public static func buildExpression(_ elements: [T]) -> Component {
        elements
    }
    
    public static func buildExpression(_ element: Element) -> Component {
        [T(from: element)]
    }

    public static func buildExpression(_ elements: [Element]) -> Component {
        elements.map(T.init)
    }
}

public protocol ElementInitializable {
    init(from element: Element)
}
