import UIKit

/// `AttributedText` allows you to apply strongly-typed attributes to strings (much like the `AttributedString` type
/// introduced in iOS 15). You can then access the `attributedString` property to get an attributed string with those
/// attributes applied.
///
/// For example:
///
/// ```swift
/// var text = AttributedText(string: "Hello, world")
/// // Apply a font to the entire range
/// text.font = .systemFont(ofSize: 20)
///
/// // Apply a color to part of the string
/// let range = text.string.range(of: "world")!
/// text[range].color = .blue
///
/// // Render the attributed text
/// let label = AttributedLabel(attributedText: text.attributedString)
/// ```
///
@dynamicMemberLookup public struct AttributedText {

    /// The wrapped string, with no attributes.
    public let string: String

    /// An `NSAttributedString` representation of the attributed text.
    public var attributedString: NSAttributedString {
        // Returns a copy so that you can't mutate the underlying storage.
        NSAttributedString(attributedString: mutableAttributedString)
    }

    /// An iterable view into segments of the attributed string, each of which indicates where a run of identical
    /// attributes begins or ends.
    ///
    public var runs: [Run] {
        var runs: [Run] = []

        mutableAttributedString.enumerateAttributes(
            in: NSRange(entireRange, in: string),
            options: []
        ) { attributes, range, _ in
            guard let range = Range(range, in: string) else {
                return
            }

            let attributes = TextAttributeContainer(storage: attributes)
            runs.append(Run(range: range, attributes: attributes))
        }

        return runs
    }

    private var mutableAttributedString: NSMutableAttributedString

    /// Create some `AttributedText` from a plain string.
    public init(_ string: String) {
        self.string = string
        self.mutableAttributedString = NSMutableAttributedString(string: string)
    }

    /// Create some `AttributedText` from an attributed string. The attributes are preserved.
    public init(_ attributedString: NSAttributedString) {
        self.string = attributedString.string
        self.mutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
    }

    public func range(of aString: some StringProtocol) -> Range<String.Index>? {
        string.range(of: aString)
    }

    /// Dynamic member getter or setter for any attributes defined on `TextAttributeContainer`.
    /// Applies the attribute to the entire range of text, for example:
    ///
    /// ```swift
    /// var text = AttributedText(string: "Hello, world")
    /// text.font = .systemFont(ofSize: 20)
    /// ```
    /// Note that only attributes applying to the entire range will be returned. For example, if the text
    /// has two different `font` attributes, then `text.font` will be `nil`.
    ///
    public subscript<Value>(dynamicMember keyPath: WritableKeyPath<TextAttributeContainer, Value>) -> Value {
        get {
            self[entireRange][keyPath: keyPath]
        }
        set {
            self[entireRange][keyPath: keyPath] = newValue
        }
    }

    /// Get or set a `TextAttributeContainer` for the provided range of text. This allows you to set attributes
    /// for specific ranges using strong types:
    ///
    /// ```swift
    /// var text = AttributedText(string: "Hello, world")
    /// let range = text.string.range(of: "Hello")!
    /// text[range].font = .systemFont(ofSize: 20)
    /// ```
    ///
    /// Note that the returned `TextAttributeContainer` will only contain attributes that apply to the entire subscript
    /// range. (Setting an attribute will set it across the subscript range regardless of any existing contents).
    ///
    public subscript<R>(range: R) -> TextAttributeContainer where R: RangeExpression, R.Bound == String.Index {
        get {
            let range = NSRange(range, in: string)
            return makeAttributeStore(range: range)
        }
        set {
            let range = NSRange(range, in: string)
            addAttributes(attributes: newValue, to: range)
        }
    }

    /// Concatenate two pieces of `AttributedText` together.
    ///
    public static func + (lhs: AttributedText, rhs: AttributedText) -> AttributedText {
        let newString = NSMutableAttributedString(attributedString: lhs.mutableAttributedString)
        newString.append(rhs.mutableAttributedString)
        return AttributedText(newString)
    }

    private var entireRange: Range<String.Index> {
        string.startIndex..<string.endIndex
    }

    private mutating func addAttributes(attributes: TextAttributeContainer, to range: NSRange) {
        if !isKnownUniquelyReferenced(&mutableAttributedString) {
            mutableAttributedString = NSMutableAttributedString(attributedString: mutableAttributedString)
        }

        let oldAttributes = makeAttributeStore(range: range)
        let oldKeys = Set(oldAttributes.storage.keys)
        let newKeys = Set(attributes.storage.keys)
        let removedKeys = oldKeys.subtracting(newKeys)

        for key in removedKeys {
            mutableAttributedString.removeAttribute(key, range: range)
        }

        mutableAttributedString.addAttributes(attributes.storage, range: range)
    }

    /// The implementation of this function may not be intuitive, but is necessary due to how enumerating attributes
    /// works. For example, consider the string "Block" with the font attribute set for the whole string, the color
    /// red set for the range of "Blo" and the color blue set for the range of "ck".
    ///
    /// If we get the attributes for the entire range of the string, the desired output is a
    /// `TextAttributeContainer` with only the `font` specified, since it's the only attribute that applies to that
    /// whole range. If we enumerate the attributes of the string however, the system will give us two results:
    ///
    /// - The range of "Blo" with the font and red color in the dictionary
    /// - The range of "ck" with the font and the blue color in the dictionary
    ///
    /// Now we need to "merge" attributes that match across the whole range, but in practice we cannot do that: the
    /// dictionary contains values of type "any" so we cannot compare them. We know that a font attribute is present
    /// in both the first range and second range, but we don't know if the value is equal, and therefor valid for
    /// the entire range.
    ///
    /// This leads the implementation below: first, collect the attributes present in the range at all. Secondly,
    /// enumerate the attributes individually. The system finds the longest effective range of attributes for us, so
    /// if the range of the found attribute matches the range we're checking, add the attribute to our text container.
    ///
    private func makeAttributeStore(range: NSRange) -> TextAttributeContainer {
        var store = TextAttributeContainer.empty
        var attributesInRange: Set<NSAttributedString.Key> = []

        mutableAttributedString.enumerateAttributes(
            in: range,
            options: []
        ) { attributes, _, _ in
            attributesInRange.formUnion(attributes.keys)
        }

        for attribute in attributesInRange {
            mutableAttributedString.enumerateAttribute(
                attribute,
                in: range,
                options: []
            ) { value, attributeRange, _ in
                if let value = value, attributeRange == range {
                    store.storage[attribute] = value
                }
            }
        }

        return store
    }
}

extension AttributedText {

    /// A Run represents a range of identical attributes in the attributed text.
    ///
    /// You can access any properties of `TextAttributeContainer` on this type using dynamic member lookup.
    ///
    @dynamicMemberLookup public struct Run {
        /// The range of the run of attributes.
        ///
        public let range: Range<String.Index>

        /// The attributes that apply to this run.
        ///
        /// Note that you can access properties of the attribute container directly on the `Run` itself, since it
        /// implements dynamic member look up.
        ///
        public let attributes: TextAttributeContainer

        /// Dynamic member getter for the `TextAttributeContainer` of this run.
        ///
        public subscript<Value>(dynamicMember keyPath: KeyPath<TextAttributeContainer, Value>) -> Value {
            attributes[keyPath: keyPath]
        }

        init(range: Range<String.Index>, attributes: TextAttributeContainer) {
            self.range = range
            self.attributes = attributes
        }
    }
}
