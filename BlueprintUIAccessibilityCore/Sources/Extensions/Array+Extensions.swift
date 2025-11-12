import Foundation


extension [String?] {
    /// Joins non-empty optional strings into a single string formatted for use in accessibility contexts.
    internal func joinedAccessibilityString() -> String? {
        let joined = compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
        return joined.isEmpty ? nil : joined
    }
}

extension Array where Element: Equatable {

    /// Returns an array where only the first instance of any duplicated element is included.
    public var removingDuplicates: Self {
        reduce([]) { $0.contains($1) ? $0 : $0 + [$1] }
    }
}
