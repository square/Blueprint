/// Generic result builder for converting blocks of `Child...` into `[Child]`.
@_functionBuilder // change to @resultBuilder when we upgrade to Swift 5.4.
public struct StackChildBuilder {
    public typealias Component = [StackChild]

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
    
    public static func buildExpression(_ element: StackChild) -> Component {
        [element]
    }
    
    public static func buildExpression(_ elements: [StackChild]) -> Component {
        elements
    }
    
    public static func buildExpression(_ element: Element) -> Component {
        [element.stackChild()]
    }

    public static func buildExpression(_ elements: [Element]) -> Component {
        elements.map { $0.stackChild() }
    }
}
