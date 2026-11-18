import Foundation


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
