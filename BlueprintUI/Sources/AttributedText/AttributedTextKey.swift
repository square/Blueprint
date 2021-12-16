import UIKit

/// Define `AttributedText` keys using this protocol. Keys must have an attribute name
/// and an associated type for the attribute.
///
/// After defining a key, enable dynamic member access to it by extending `TextAttributeContainer`
/// with a property for getting and setting setting the value. This property should generally be optional,
/// since the text may not have that property defined.
///
public protocol AttributedTextKey {
    associatedtype Value: Equatable
    static var name: NSAttributedString.Key { get }
}

// MARK: - Built-in attribute keys

// MARK: Font

public enum FontKey: AttributedTextKey {
    public typealias Value = UIFont
    public static var name: NSAttributedString.Key { .font }
}

extension TextAttributeContainer {
    public var font: UIFont? {
        get { self[FontKey.self] }
        set { self[FontKey.self] = newValue }
    }
}

// MARK: Color

public enum ColorKey: AttributedTextKey {
    public typealias Value = UIColor
    public static var name: NSAttributedString.Key { .foregroundColor }
}

extension TextAttributeContainer {
    public var color: UIColor? {
        get { self[ColorKey.self] }
        set { self[ColorKey.self] = newValue }
    }
}

// MARK: Tracking

public enum TrackingKey: AttributedTextKey {
    public typealias Value = CGFloat
    public static var name: NSAttributedString.Key { kCTTrackingAttributeName as NSAttributedString.Key }
}

extension TextAttributeContainer {
    public var tracking: CGFloat? {
        get { self[TrackingKey.self] }
        set { self[TrackingKey.self] = newValue }
    }
}

// MARK: Underline

public enum UnderlineStyleKey: AttributedTextKey {
    public typealias Value = Int
    public static var name: NSAttributedString.Key { .underlineStyle }
}

extension TextAttributeContainer {
    public var underlineStyle: NSUnderlineStyle? {
        get { self[UnderlineStyleKey.self].flatMap { NSUnderlineStyle(rawValue: $0) } }
        set { self[UnderlineStyleKey.self] = newValue?.rawValue }
    }
}

public enum UnderlineColorKey: AttributedTextKey {
    public typealias Value = UIColor
    public static var name: NSAttributedString.Key { .underlineColor }
}

extension TextAttributeContainer {
    public var underlineColor: UIColor? {
        get { self[UnderlineColorKey.self] }
        set { self[UnderlineColorKey.self] = newValue }
    }
}

// MARK: Paragraph style

public enum ParagraphStyleKey: AttributedTextKey {
    public typealias Value = NSParagraphStyle
    public static var name: NSAttributedString.Key { .paragraphStyle }
}

extension TextAttributeContainer {
    public var paragraphStyle: NSParagraphStyle? {
        get { self[ParagraphStyleKey.self] }
        set { self[ParagraphStyleKey.self] = newValue }
    }
}

// MARK: Link

public enum LinkKey: AttributedTextKey {
    public typealias Value = URL
    public static var name: NSAttributedString.Key { .link }
}

extension TextAttributeContainer {
    public var link: URL? {
        get { self[LinkKey.self] }
        set { self[LinkKey.self] = newValue }
    }
}
