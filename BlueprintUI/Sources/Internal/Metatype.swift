import Foundation

/// A wrapper to make metatypes easier to work with, providing Equatable, Hashable, and
/// CustomStringConvertible.
struct Metatype: Hashable, CustomStringConvertible {
    var type: Any.Type

    init(_ type: Any.Type) {
        self.type = type
    }

    var description: String {
        "\(type)"
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(type))
    }

    static func == (lhs: Metatype, rhs: Metatype) -> Bool {
        lhs.type == rhs.type
    }
}
