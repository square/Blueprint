import CoreGraphics

/// An element that dynamically builds its content based on the environment.
///
/// Use this element to build elements whose contents may change depending on the `Environment`.
///
/// ## Example
///
///     EnvironmentReader { environment -> Element in
///         MyElement(
///             foo: environment.foo
///         )
///     }
///
/// - seealso: ProxyElement
/// - seealso: Environment
public struct EnvironmentReader: Element {

    /// Return the contents of this element in the given environment.
    var elementRepresentation: (Environment) -> Element

    public init(elementRepresentation: @escaping (_ environment: Environment) -> Element) {
        self.elementRepresentation = elementRepresentation
    }

    public var content: ElementContent {
        ElementContent { _, environment in
            self.elementRepresentation(environment)
        }
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        nil
    }
}
