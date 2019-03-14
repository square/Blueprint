/// Used to identify elements during an update pass. If no key identifier is present, the fallback behavior is to
/// identify the element by its index.
enum ElementIdentifier: Hashable {

    /// The element represented by this component was assigned a specific key.
    case key(String)

    /// The element represented by this component was not assigned a specific key, so its index in the parent's array
    /// of children is used instead.
    case index(Int)

    internal init(key: String?, index: Int) {
        if let key = key {
            self = .key(key)
        } else {
            self = .index(index)
        }
    }

    /// Returns the reuse identifier of this component (if provided).
    var key: String? {
        switch self {
        case .key(let key):
            return key
        default:
            return nil
        }
    }

}

extension ElementIdentifier: CustomStringConvertible {

    var description: String {
        switch self {
        case let .key(string):
            return string
        case let .index(index):
            return "(\(index))"
        }
    }

}
