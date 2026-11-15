import Foundation


extension [String?] {
    /// Joins non-empty optional strings into a single string formatted for use in accessibility contexts.
    package func joinedAccessibilityString() -> String? {
        let joined = compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
        return joined.isEmpty ? nil : joined
    }
}

extension Array where Element: Equatable {

    /// Returns an array where only the first instance of any duplicated element is included.
    package var removingDuplicates: Self {
        reduce([]) { $0.contains($1) ? $0 : $0 + [$1] }
    }
}

extension [NSAttributedString?] {
    package func joinedAccessibilityText() -> NSAttributedString? {
        let result = NSMutableAttributedString(string: "")
        for text in compactMap({ $0 }) where text.length > 0 {
            if result.length > 0 { result.append(NSAttributedString(string: ", ")) }
            result.append(text)
        }
        return result.length == 0 ? nil : NSAttributedString(attributedString: result)
    }
}
