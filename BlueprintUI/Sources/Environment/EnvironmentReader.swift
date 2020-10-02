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
        return ElementContent { (_, environment) in
            self.elementRepresentation(environment)
        }
    }

    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return nil
    }
}


extension Element {
    
    /// Returns a new element, created by the passed in function which gives
    /// you access to the current state of the `Environment`.
    /// ```
    /// myElement.withEnvironment { env, element in
    ///     element.inset(by: env.safeAreaInsets)
    /// }
    /// ```
    public func withEnvironment(_ map : @escaping (Self, Environment) -> Element) -> Element
    {
        EnvironmentReader { env in
            map(self, env)
        }
    }
}
