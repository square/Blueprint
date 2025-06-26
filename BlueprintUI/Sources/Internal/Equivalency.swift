import Foundation

public enum EquivalencyContext: Hashable, Sendable {
    case all
    case layout
}

public protocol ContextuallyEquivalent {

    /// Allows a type to express equivilancy within certain contexts. For example, an Environment that represents dark mode would be equivilant to an Environment that represents light mode in a `layout` context, but not in `all` contexts.
    /// - Parameters:
    ///   - other: The instance of the type being compared against.
    ///   - context: The context to compare within.
    /// - Returns: Whether or not the other instance is equivalent in the specified context.
    func isEquivalent(to other: Self?, in context: EquivalencyContext) -> Bool

}

// Default implementation that always returns strict equivalency.
extension ContextuallyEquivalent where Self: Equatable {

    func isEquivalent(to other: Self?, in context: EquivalencyContext) -> Bool {
        if self == other {
            true
        } else {
            false
        }
    }

}

#if DEBUG
#if swift(>=6.2)

import Playgrounds

struct SomeTextElement: ContextuallyEquivalent, Equatable {
    var text = "Hello"
    var isDarkMode = false
}

struct SomeOtherTextElement: ContextuallyEquivalent {
    var text = "Hello"
    var isDarkMode = false
}

extension SomeTextElement: ContextuallyEquivalent {
    func isEquivalent(to other: SomeOtherType, in context: EquivalencyContext) -> Bool {
        switch context {
        case .all:
            self == other
        case .layout:
            text == other.text
        }
    }
}

#Playground {

    var a = SomeTextElement()
    var b = SomeTextElement()
    a == b
    a.isEquivalent(to: b, in: .all)
    a.isEquivalent(to: b, in: .layout)
    a.isDarkMode = true
    a == b
    a.isEquivalent(to: b, in: .all)
    a.isEquivalent(to: b, in: .layout)
    var c = SomeOtherTextElement()
    var d = SomeOtherTextElement()
    c.isEquivalent(to: d, in: .all)
}

#endif
#endif
