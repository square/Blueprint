import BlueprintUI
import Foundation
import UIKit

public struct AttributedLabel: Element, Hashable {

    /// The attributed text to render in the label.
    ///
    /// If you customize the line break mode using an `NSParagraphStyle`, the mode will be normalized
    /// based on the number of lines allowed. This is because some line break modes are incompatible
    /// with multi-line text rendering in TextKit, which is used to detect where links are in the text.
    /// Some modes also break line height adjustment in single-line labels, so these are also normalized.
    ///
    /// Specifically:
    ///
    /// - 1 line labels with a mode of `byCharWrapping` or `byWordWrapping` will be normalized to `byClipping`.
    /// - Multiline labels with a mode of `byTruncatingHead` or `byTruncatingMiddle`
    ///   will be normalized to `byTruncatingTail`.
    ///
    public var attributedText: NSAttributedString

    public var numberOfLines: Int = 0

    /// A shadow to display behind the label's text. Defaults to no shadow.
    ///
    /// - Note: This shadow is applied using the backing view's `CALayer`, and will affect the
    /// entire label. To apply a shadow to only a portion of text, you can instead set
    /// `NSAttributedString.Key.shadow` on the string, but note that those shadows may be clipped
    /// by the bounds of the backing view.
    public var shadow: TextShadow?

    /// An offset that will be applied to the rect used by `drawText(in:)`.
    ///
    /// This can be used to adjust the positioning of text within each line's frame, such as adjusting
    /// the way text is distributed within the line height.
    public var textRectOffset: UIOffset = .zero

    /// Determines if the label should be included when navigating the UI via accessibility.
    public var isAccessibilityElement = true

    /// A Boolean value that determines whether the label reduces the text’s font
    /// size to fit the title string into the label’s bounding rectangle.
    ///
    /// Normally, the label draws the text with the font you specify in the font property.
    /// If this property is true, and the text in the text property exceeds the label’s bounding rectangle,
    /// the label reduces the font size until the text fits or it has scaled the font down to the minimum
    /// font size. The default value for this property is false.
    ///
    /// If you change it to true, be sure that you also set an appropriate minimum
    /// font scale by modifying the minimumScaleFactor property.
    ///
    /// This autoshrinking behavior is only intended for use with a single-line label.
    public var adjustsFontSizeToFitWidth: Bool = false

    /// The minimum scale factor for the label’s text.
    ///
    /// If the adjustsFontSizeToFitWidth is true, use this property to specify the
    /// smallest multiplier for the current font size that yields an acceptable
    /// font size for the label’s text.
    ///
    /// If you specify a value of 0 for this property, the label doesn't scale the text down.
    /// The default value of this property is 0.
    public var minimumScaleFactor: CGFloat = 0

    /// A Boolean value that determines whether the label tightens text before truncating.
    ///
    /// When the value of this property is true, the label tightens intercharacter spacing
    /// of its text before allowing any truncation to occur. The label determines the
    /// maximum amount of tightening automatically based on the font, current line width,
    /// line break mode, and other relevant information.
    ///
    /// This autoshrinking behavior is only intended for use with a single-line label.
    ///
    /// The default value of this property is false.
    public var allowsDefaultTighteningForTruncation: Bool = false

    /// A set of accessibility traits that should be applied to the label, these will be merged with any existing traits.
    public var accessibilityTraits: Set<AccessibilityElement.Trait>?

    /// A set of data types to detect and automatically link in the label.
    public var linkDetectionTypes: Set<LinkDetectionType>?

    /// A set of attributes to apply to links in the string.
    public var linkAttributes: [NSAttributedString.Key: AnyHashable] = [
        .foregroundColor: UIColor.systemBlue,
    ]

    /// A set of attributes to apply to links when they are touched.
    public var activeLinkAttributes: [NSAttributedString.Key: AnyHashable] = [
        .foregroundColor: UIColor.systemBlue.withAlphaComponent(0.3),
    ]

    public init(attributedText: NSAttributedString, configure: (inout Self) -> Void = { _ in }) {
        self.attributedText = attributedText

        configure(&self)
    }

    public var content: ElementContent {
        struct Measurer {
            private static let prototypeLabel = LabelView()

            func measure(model: AttributedLabel, in constraint: SizeConstraint, environment: Environment) -> CGSize {
                let label = Self.prototypeLabel
                label.update(model: model, environment: environment, isMeasuring: true)
                return label.sizeThatFits(constraint.maximum)
            }
        }

        return ElementContent { sizeConstraint, environment -> CGSize in
            Measurer().measure(model: self, in: sizeConstraint, environment: environment)
        }
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        LabelView.describe { config in
            config.frameRoundingBehavior = .prioritizeSize
            config.apply { view in
                view.update(model: self, environment: context.environment, isMeasuring: false)
            }
        }
    }
}


// MARK: - Models

extension AttributedLabel {
    /// Types of data that can be detected and automatically turned into links.
    ///
    /// Corresponds to `NSTextCheckingResult.CheckingType` types.
    ///
    public enum LinkDetectionType: Equatable, Hashable {
        /// Detect date strings. Tapping a date opens the calendar to that date.
        case date
        /// Detect addresses. Tapping the address opens Maps with that address.
        case address
        /// Detect URLs. Tapping the link opens the URL.
        case link
        /// Detect phone numbers. Tapping the phone number prompts the user to call it.
        case phoneNumber

        var checkingType: NSTextCheckingResult.CheckingType {
            switch self {
            case .date: return .date
            case .address: return .address
            case .link: return .link
            case .phoneNumber: return .phoneNumber
            }
        }
    }
}

// MARK: View implementation


extension AttributedLabel {

    final class LabelView: UILabel {
        /// The touch handling logic explicitly tracks the active links when touches begin, so if you drag outside
        /// the link and touch up over another link, it just cancels the tap rather than accidentally opening
        /// a different link.
        private var trackingLinks: [Link]?

        private var layoutDirection: Environment.LayoutDirection = .leftToRight
        private var linkDetectionTypes: Set<LinkDetectionType> = []
        private var linkAttributes: [NSAttributedString.Key: Any] = [:]
        private var activeLinkAttributes: [NSAttributedString.Key: Any] = [:]
        private var links: [Link] = []

        private var textRectOffset: UIOffset = .zero {
            didSet {
                if oldValue != textRectOffset {
                    setNeedsDisplay()
                }
            }
        }

        /// The view needs to keep track of the current index for the accessibility rotor.
        private var accessibilityLinkIndex = -1

        /// These elements need to be retained by the view, and cannot be created inside the
        /// `accessibilityCustomRotors` getter.
        private var accessibilityLinks: [LinkAccessibilityElement] = []

        override var accessibilityCustomRotors: [UIAccessibilityCustomRotor]? {
            set { fatalError() }
            get {
                accessibilityLinks.isEmpty
                    ? []
                    : [
                        UIAccessibilityCustomRotor(systemType: .link) { [weak self] predicate in
                            guard let self = self, !self.accessibilityLinks.isEmpty else {
                                return nil
                            }

                            self.accessibilityLinkIndex += predicate.searchDirection == .next ? 1 : -1
                            self.accessibilityLinkIndex = min(
                                self.accessibilityLinks.count - 1,
                                self.accessibilityLinkIndex
                            )
                            self.accessibilityLinkIndex = max(0, self.accessibilityLinkIndex)

                            let link = self.accessibilityLinks[self.accessibilityLinkIndex]
                            return UIAccessibilityCustomRotorItemResult(targetElement: link, targetRange: nil)
                        },
                    ]
            }
        }

        var urlHandler: URLHandler?

        func update(model: AttributedLabel, environment: Environment, isMeasuring: Bool) {
            let previousAttributedText = attributedText

            linkAttributes = model.linkAttributes
            activeLinkAttributes = model.activeLinkAttributes
            linkDetectionTypes = model.linkDetectionTypes ?? []

            attributedText = model
                .attributedText
                .normalizingForView(with: model.numberOfLines)

            numberOfLines = model.numberOfLines
            textRectOffset = model.textRectOffset

            if !isMeasuring {
                updateFontFitting(with: model)
            }

            isAccessibilityElement = model.isAccessibilityElement
            updateAccessibilityTraits(with: model)

            urlHandler = environment.urlHandler
            layoutDirection = environment.layoutDirection

            if !isMeasuring {
                if previousAttributedText != attributedText {
                    links = attributedLinks(in: model.attributedText) + detectedDataLinks(in: model.attributedText)
                    accessibilityLinks = accessibilityLinks(for: links, in: model.attributedText)
                }

                if let shadow = model.shadow {
                    layer.shadowRadius = shadow.radius
                    layer.shadowOpacity = Float(shadow.opacity)
                    layer.shadowOffset = CGSize(width: shadow.offset.horizontal, height: shadow.offset.vertical)
                    layer.shadowColor = shadow.color.cgColor

                    // For performance reasons, we should set `shadowPath`, but that's not practical
                    // with text content. Instead, enable rasterization on this layer, which will
                    // cache a bitmap offscreen.
                    layer.shouldRasterize = true
                    layer.rasterizationScale = layer.contentsScale
                } else {
                    layer.shadowOpacity = 0
                    layer.shouldRasterize = false
                }

            }

            applyLinkColors()
        }

        private func updateFontFitting(with model: AttributedLabel) {

            adjustsFontSizeToFitWidth = model.adjustsFontSizeToFitWidth
            minimumScaleFactor = model.minimumScaleFactor
            allowsDefaultTighteningForTruncation = model.allowsDefaultTighteningForTruncation
        }

        private func updateAccessibilityTraits(with model: AttributedLabel) {

            if let traits = model.accessibilityTraits {

                var traits = UIAccessibilityTraits(with: traits)

                if traits.contains(.updatesFrequently) {
                    /// `UILabel` has the `.staticText` trait by default.
                    /// If we explicitly set `.updatesFrequently` this should be removed.
                    traits.subtract(.staticText)
                }

                accessibilityTraits = traits
            }
        }

        override func drawText(in rect: CGRect) {
            super.drawText(in: rect.offsetBy(dx: textRectOffset.horizontal, dy: textRectOffset.vertical))
        }

        func makeTextStorage() -> NSTextStorage? {
            guard let attributedText = attributedText, attributedText.length > 0 else {
                return nil
            }

            var lineBreakAdjustedText = AttributedText(attributedText)

            let textStorage = NSTextStorage()
            let layoutManager = NSLayoutManager()
            let textContainer = NSTextContainer()

            textContainer.lineFragmentPadding = 0
            textContainer.maximumNumberOfLines = numberOfLines
            textContainer.size = bounds.size

            // If the paragraph style is set, we need to adjust its lineBreakMode
            // to one that works with NSTextContainer.
            if let paragraphStyle = lineBreakAdjustedText.paragraphStyle?.mutableCopy() as? NSMutableParagraphStyle {
                let adjustedLineBreakMode = paragraphStyle.lineBreakMode.textContainerMode(for: numberOfLines)
                paragraphStyle.lineBreakMode = adjustedLineBreakMode
                lineBreakAdjustedText.paragraphStyle = paragraphStyle
            }

            layoutManager.usesFontLeading = false
            layoutManager.addTextContainer(textContainer)
            textStorage.addLayoutManager(layoutManager)
            textStorage.setAttributedString(lineBreakAdjustedText.attributedString)

            return textStorage
        }

        private func links(at location: CGPoint) -> [Link] {
            guard let textStorage = makeTextStorage(),
                  let layoutManager = textStorage.layoutManagers.first,
                  let textContainer = layoutManager.textContainers.first
            else {
                return []
            }

            func alignmentMultiplier() -> CGFloat {
                var alignment: NSTextAlignment = .natural

                textStorage.enumerateAttribute(
                    .paragraphStyle,
                    in: textStorage.entireRange,
                    options: []
                ) { style, range, continuePointer in
                    if let style = style as? NSParagraphStyle, range == textStorage.entireRange {
                        alignment = style.alignment
                        continuePointer.pointee = false
                    }
                }

                switch (alignment, layoutDirection) {
                case (.left, _),
                     (.justified, _),
                     (.natural, .leftToRight):
                    return 0
                case (.right, _),
                     (.natural, .rightToLeft):
                    return 1
                case (.center, _):
                    return 0.5
                @unknown default:
                    return 0
                }
            }

            let labelSize = bounds.size
            let alignmentMultiplier = alignmentMultiplier()
            let textBoundingBox = layoutManager.usedRect(for: textContainer)
            let textContainerOffset = CGPoint(
                x: (labelSize.width - textBoundingBox.size.width) * alignmentMultiplier - textBoundingBox.origin.x,
                y: (labelSize.height - textBoundingBox.size.height) * alignmentMultiplier - textBoundingBox.origin.y
            )
            let locationInTextContainer = CGPoint(
                x: location.x - textContainerOffset.x,
                y: location.y - textContainerOffset.y
            )

            guard textBoundingBox.contains(locationInTextContainer) else {
                return []
            }

            let indexOfCharacter = layoutManager.characterIndex(
                for: locationInTextContainer,
                in: textContainer,
                fractionOfDistanceBetweenInsertionPoints: nil
            )

            return links.filter { $0.range.contains(indexOfCharacter) }
        }

        private func attributedLinks(in string: NSAttributedString) -> [Link] {
            var links: [Link] = []

            string.enumerateAttribute(
                .link,
                in: string.entireRange,
                options: []
            ) { link, range, _ in
                if let link = link as? URL {
                    links.append(.init(url: link, range: range))
                } else if let link = link as? String, let url = URL(string: link) {
                    links.append(.init(url: url, range: range))
                }
            }

            return links
        }

        private func detectedDataLinks(in string: NSAttributedString) -> [Link] {
            guard !linkDetectionTypes.isEmpty else {
                return []
            }

            let types = NSTextCheckingResult.CheckingType(linkDetectionTypes)

            guard let detector = try? NSDataDetector(types: types.rawValue) else {
                return []
            }

            var links: [Link] = []

            detector.enumerateMatches(
                in: string.string,
                options: [],
                range: string.entireRange
            ) { result, _, _ in
                guard let result = result else {
                    return
                }

                switch result.resultType {
                case .phoneNumber:
                    if let phoneNumber = result.phoneNumber {
                        let charactersToRemove = CharacterSet.decimalDigits.inverted
                        let trimmedPhoneNumber = phoneNumber.components(separatedBy: charactersToRemove).joined()
                        if let url = URL(string: "tel:\(trimmedPhoneNumber)") {
                            links.append(.init(url: url, range: result.range))
                        }
                    }

                case .link:
                    if let url = result.url {
                        links.append(.init(url: url, range: result.range))
                    }

                case .address:
                    if let addressComponents = result.addressComponents {
                        let components = [
                            addressComponents[.name],
                            addressComponents[.organization],
                            addressComponents[.street],
                            addressComponents[.city],
                            addressComponents[.zip],
                            addressComponents[.country],
                        ]

                        let address = components
                            .compactMap { $0 }
                            .joined(separator: " ")

                        if let urlQuery = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                           let url = URL(string: "https://maps.apple.com/?address=\(urlQuery)")
                        {
                            links.append(.init(url: url, range: result.range))
                        }
                    }

                case .date:
                    if let date = result.date,
                       let url = URL(string: "calshow:\(date.timeIntervalSinceReferenceDate)")
                    {
                        links.append(.init(url: url, range: result.range))
                    }

                default:
                    break
                }
            }

            return links
        }

        private func accessibilityLinks(for links: [Link], in string: NSAttributedString) -> [LinkAccessibilityElement] {
            links
                .sorted(by: { $0.range.location < $1.range.location })
                .compactMap { link in
                    guard NSIntersectionRange(string.entireRange, link.range).length > 0 else {
                        return nil
                    }

                    return LinkAccessibilityElement(
                        container: self,
                        label: string.attributedSubstring(from: link.range).string,
                        link: link
                    )
                }
        }

        func applyLinkColors(activeLinks: [Link] = []) {
            let mutableString = NSMutableAttributedString(attributedString: attributedText ?? .init(string: ""))

            for link in links {
                mutableString.addAttributes(linkAttributes, range: link.range)
            }

            for link in activeLinks {
                mutableString.addAttributes(activeLinkAttributes, range: link.range)
            }

            attributedText = mutableString
        }

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard links.isEmpty == false, let first = touches.first else {
                return super.touchesBegan(touches, with: event)
            }

            let touchedLinks = links(at: first.location(in: self))
            trackingLinks = touchedLinks
            applyLinkColors(activeLinks: touchedLinks)
        }

        override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard links.isEmpty == false, let first = touches.first, let trackingLinks = trackingLinks else {
                return super.touchesMoved(touches, with: event)
            }

            let touchedLinks = links(at: first.location(in: self))
            let activeLinks = Set(touchedLinks).intersection(trackingLinks)
            applyLinkColors(activeLinks: Array(activeLinks))
        }

        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard links.isEmpty == false, let first = touches.first, let trackingLinks = trackingLinks else {
                return super.touchesEnded(touches, with: event)
            }

            let touchedLinks = links(at: first.location(in: self))
            let activeLinks = Set(touchedLinks).intersection(trackingLinks)
            for link in activeLinks {
                urlHandler?.onTap(url: link.url)
            }

            self.trackingLinks = nil
            applyLinkColors()
        }

        override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
            trackingLinks = nil
            applyLinkColors()
        }
    }

}

extension AttributedLabel {
    struct Link: Equatable, Hashable {
        var url: URL
        var range: NSRange
    }

    private final class LinkAccessibilityElement: UIAccessibilityElement {
        private let link: AttributedLabel.Link
        private var container: LabelView? { accessibilityContainer as? LabelView }

        init(
            container: LabelView,
            label: String,
            link: AttributedLabel.Link
        ) {
            self.link = link
            super.init(accessibilityContainer: container)
            accessibilityLabel = label
        }

        override var accessibilityFrameInContainerSpace: CGRect {
            set { fatalError() }
            get {
                guard let container = container,
                      let textStorage = container.makeTextStorage(),
                      let layoutManager = textStorage.layoutManagers.first,
                      let textContainer = layoutManager.textContainers.first
                else {
                    return .zero
                }

                let glyphRange = layoutManager.glyphRange(forCharacterRange: link.range, actualCharacterRange: nil)
                return layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
            }
        }

        override func accessibilityActivate() -> Bool {
            container?.urlHandler?.onTap(url: link.url)
            return true
        }
    }
}

extension Element {
    /// Handle links opened in any `AttributedLabel` within this element using the provided closure.
    ///
    public func onLinkTapped(_ onTap: @escaping (URL) -> Void) -> Element {
        adaptedEnvironment(keyPath: \.urlHandler, value: ClosureURLHandler(onTap: onTap))
    }
}

// MARK: Extensions

extension UIOffset: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(horizontal)
        hasher.combine(vertical)
    }
}

extension NSAttributedString.Key {
    fileprivate static var labelLink: NSAttributedString.Key {
        NSAttributedString.Key(rawValue: "BlueprintUICommonControls.AttributedLabel.Link")
    }
}

private enum LabelLinkKey: AttributedTextKey {
    typealias Value = URL
    static var name: NSAttributedString.Key { .labelLink }
}

extension TextAttributeContainer {
    fileprivate var labelLink: URL? {
        get { self[LabelLinkKey.self] }
        set { self[LabelLinkKey.self] = newValue }
    }
}

extension NSLineBreakMode {
    func textContainerMode(for numberOfLines: Int) -> NSLineBreakMode {
        let wrappingModes: Set<NSLineBreakMode> = Set([.byWordWrapping, .byCharWrapping])
        if numberOfLines != 1 && !wrappingModes.contains(self) {
            return .byWordWrapping
        }
        if numberOfLines == 1 && wrappingModes.contains(self) {
            return .byClipping
        }
        return self
    }
}

extension NSAttributedString {
    fileprivate var entireRange: NSRange {
        NSRange(location: 0, length: length)
    }

    fileprivate func normalizingForView(with numberOfLines: Int) -> NSAttributedString {
        var attributedText = AttributedText(self)

        for run in attributedText.runs {
            /// Apply the default label font to any runs with no font attribute. This ensures the NSTextStorage is rendering
            /// the same attributes as the label.
            if run.font == nil {
                attributedText[run.range].font = UIFont.systemFont(ofSize: UIFont.labelFontSize)
            }

            /// Replace `link` attributes with our custom `labelLink` attribute to avoid default
            /// UILabel styling of `link` ranges.
            if let link = run.link {
                attributedText[run.range].link = nil
                attributedText[run.range].labelLink = link
            }
        }

        if let paragraphStyle = attributedText.paragraphStyle?.mutableCopy() as? NSMutableParagraphStyle {
            let invalidMultiLineModes: Set<NSLineBreakMode> = [.byTruncatingHead, .byTruncatingMiddle]
            let invalidSingleLineModes: Set<NSLineBreakMode> = [.byCharWrapping, .byWordWrapping]

            // These line break modes don't work with NSTextContainer where numberOfLines is not 1, breaking link
            // detection. Those modes also don't really make sense with multiple lines anyway - UILabel will render
            // only the last line with that mode. Normalize them to truncating tail instead.
            if numberOfLines != 1 && invalidMultiLineModes.contains(paragraphStyle.lineBreakMode) {
                paragraphStyle.lineBreakMode = .byTruncatingTail
            }

            // These line break modes don't work when numberOfLines is 1, and they break line height adjustments.
            // Normalize them to clipping mode instead (which renders the same on one line anyway).
            if numberOfLines == 1 && invalidSingleLineModes.contains(paragraphStyle.lineBreakMode) {
                paragraphStyle.lineBreakMode = .byClipping
            }

            attributedText.paragraphStyle = paragraphStyle
        }

        return attributedText.attributedString
    }
}

extension NSTextCheckingResult.CheckingType {
    init(_ types: Set<AttributedLabel.LinkDetectionType>) {
        var checkingType = NSTextCheckingResult.CheckingType()

        for type in types {
            checkingType.formUnion(type.checkingType)
        }

        self = checkingType
    }
}
