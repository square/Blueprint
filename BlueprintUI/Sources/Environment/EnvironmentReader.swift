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
        return ElementContent(build: self.elementRepresentation)
    }

    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return nil
    }
}
