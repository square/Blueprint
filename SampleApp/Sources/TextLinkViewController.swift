import BlueprintUI
import BlueprintUICommonControls
import UIKit

final class TextLinkViewController: UIViewController {
    private let blueprintView = BlueprintView()
    private var renderer = 0
    private var selectionEnabled = true
    private var detection = 0
    private var expandedContent = false

    private enum Example: String, CaseIterable {
        case plain = "Plain text and wrapping"
        case styled = "Attributed fonts, color, underline, and strike"
        case header = "Header font and accessibility trait"
        case links = "Multiple links and custom link color"
        case detected = "Detected URLs, phone numbers, addresses, and dates"
        case center = "Centered paragraph"
        case right = "Right-aligned paragraph"
        case rtl = "Natural RTL alignment"
        case truncation = "Two-line tail truncation"
        case fitting = "Single-line font fitting, minimum scale 0.5"
        case tightening = "Single-line tightening"
        case shadow = "Text shadow"
        case offset = "Text rectangle offset: -3 points"
        case updates = "Content updates and view reuse"
        case accessibility = "Explicit accessibility label, value, hint, and action"
        case hidden = "Visible text hidden from accessibility"
        case empty = "Empty content"
    }

    override func loadView() {
        title = "Text & Links"
        edgesForExtendedLayout = []
        view = blueprintView
        blueprintView.backgroundColor = .systemBackground
        if #unavailable(iOS 17.0) { renderer = 1 }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(update),
            name: UIContentSizeCategory.didChangeNotification,
            object: nil
        )
        update()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(false, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setToolbarHidden(true, animated: animated)
    }

    @objc private func cycleRenderer() { renderer = (renderer + 1) % 3; update() }
    @objc private func toggleSelection() { selectionEnabled.toggle(); update() }
    @objc private func cycleDetection() { detection = (detection + 1) % 6; update() }
    @objc private func changeContent() { expandedContent.toggle(); update() }

    private var detectionTypes: Set<TextLinkDetectionType> {
        switch detection {
        case 0: [.link, .phoneNumber, .address, .date]
        case 1: [.link]
        case 2: [.phoneNumber]
        case 3: [.address]
        case 4: [.date]
        default: []
        }
    }

    @objc private func update() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: ["Both", "Label", "TextView"][renderer],
            style: .plain,
            target: self,
            action: #selector(cycleRenderer)
        )
        if #unavailable(iOS 17.0) { navigationItem.rightBarButtonItem?.isEnabled = false }
        navigationItem.rightBarButtonItem?.accessibilityLabel = "Renderer: " + ["Both", "Label", "TextView"][renderer]
        toolbarItems = [
            UIBarButtonItem(
                title: "Select: \(selectionEnabled ? "on" : "off")",
                style: .plain,
                target: self,
                action: #selector(toggleSelection)
            ),
            .flexibleSpace(),
            UIBarButtonItem(
                title: "Detect: " + ["all", "URL", "phone", "address", "date", "off"][detection],
                style: .plain,
                target: self,
                action: #selector(cycleDetection)
            ),
            .flexibleSpace(),
            UIBarButtonItem(title: "Update text", style: .plain, target: self, action: #selector(changeContent)),
        ]
        blueprintView.element = Column(alignment: .fill, minimumSpacing: 16) {
            caption("Compare identical attributed content in both controls. Use the navigation button to isolate a renderer and the toolbar to change selection, detectors, and content.")
            caption("TextView selection is \(selectionEnabled ? "enabled: try selecting and copying" : "disabled: explicit links remain interactive"). Try long-press link menus, VoiceOver, larger text, and dark appearance.")
            for example in Example.allCases {
                heading(example.rawValue)
                if example == .detected {
                    caption("TextView’s native detection requires selection. Explicit attributed links work with selection off.")
                }
                if renderer != 2 {
                    caption("AttributedLabel" + ([Example.links, .detected].contains(example) ? " — legacy link support" : ""))
                    specimen(example, textView: false)
                }
                if renderer != 1 {
                    if #available(iOS 17.0, *) {
                        caption("AttributedTextView")
                        specimen(example, textView: true)
                    } else {
                        caption("AttributedTextView requires iOS 17.")
                    }
                }
            }
            if #available(iOS 17.0, *) {
                heading("TextView-only: ordered and nested native lists")
                AttributedTextView(attributedText: listText(ordered: true)) { $0.isSelectable = selectionEnabled }
                heading("TextView-only: bulleted native lists")
                AttributedTextView(attributedText: listText(ordered: false)) { $0.isSelectable = selectionEnabled }
                heading("Combined links: attributed speech and native Links rotor")
                Column(minimumSpacing: 8) {
                    AttributedTextView(attributedText: linkedText(
                        "Read the Terms.",
                        word: "Terms",
                        url: "https://example.com/terms"
                    )) { $0.isSelectable = selectionEnabled }
                    AttributedTextView(attributedText: linkedText(
                        "Read the Privacy policy.",
                        word: "Privacy policy",
                        url: "https://example.com/privacy"
                    )) { $0.isSelectable = selectionEnabled }
                }.accessibilityCombine()
            }
        }
        .inset(uniform: 20)
        .scrollable(.fittingHeight)
        .onLinkTapped { [weak self] url in self?.presentAlert(message: url.absoluteString) }
    }

    private func heading(_ text: String) -> Element {
        Label(text: text) { $0.font = .preferredFont(forTextStyle: .headline); $0.color = .label; $0.accessibilityTraits = [.header] }
    }

    private func caption(_ text: String) -> Element {
        Label(text: text) { $0.font = .preferredFont(forTextStyle: .footnote); $0.color = .secondaryLabel }
    }

    private func specimen(_ example: Example, textView: Bool) -> Element {
        let text = content(example)
        let lines = example == .truncation ? 2 : ([Example.fitting, .tightening].contains(example) ? 1 : 0)
        let shadow = example == .shadow ? TextShadow(
            radius: 1,
            opacity: 0.5,
            offset: .init(horizontal: 1, vertical: 2),
            color: .systemBlue
        ) : nil
        let offset = example == .offset ? UIOffset(horizontal: 0, vertical: -3) : .zero
        let actions: [AccessibilityElement.CustomAction] = example == .accessibility ? [.init(name: "Inspect sample", onActivation: { [weak self] in
            self?.presentAlert(message: "The custom accessibility action ran.")
            return true
        })] : []
        let element: Element
        if #available(iOS 17.0, *), textView {
            element = AttributedTextView(attributedText: text) {
                $0.isSelectable = selectionEnabled
                $0.linkDetectionTypes = example == .detected ? detectionTypes : []
                $0.linkAttributes = [.foregroundColor: UIColor.systemIndigo]
                $0.numberOfLines = lines
                $0.shadow = shadow
                $0.textRectOffset = offset
                $0.adjustsFontSizeToFitWidth = example == .fitting
                $0.minimumScaleFactor = 0.5
                $0.allowsDefaultTighteningForTruncation = example == .tightening
                $0.isAccessibilityElement = example == .hidden ? false : (example == .accessibility ? true : nil)
                $0.accessibilityTraits = example == .header ? [.header] : nil
                $0.accessibilityLabel = example == .accessibility ? "Custom spoken name" : nil
                $0.accessibilityValue = example == .accessibility ? "42" : nil
                $0.accessibilityHint = example == .accessibility ? "Use the Actions rotor to inspect this sample." : nil
                $0.accessibilityCustomActions = actions
                $0.accessibilityIdentifier = "text-view-" + example.rawValue
            }
        } else {
            element = AttributedLabel(attributedText: text) {
                $0.linkDetectionTypes = example == .detected ? detectionTypes : []
                $0.linkAttributes = [.foregroundColor: UIColor.systemIndigo]
                $0.activeLinkAttributes = [.foregroundColor: UIColor.systemIndigo.withAlphaComponent(0.3)]
                $0.numberOfLines = lines
                $0.shadow = shadow
                $0.textRectOffset = offset
                $0.adjustsFontSizeToFitWidth = example == .fitting
                $0.minimumScaleFactor = 0.5
                $0.allowsDefaultTighteningForTruncation = example == .tightening
                $0.isAccessibilityElement = example != .hidden
                $0.accessibilityTraits = example == .header ? [.header] : nil
                $0.accessibilityLabel = example == .accessibility ? "Custom spoken name" : nil
                $0.accessibilityValue = example == .accessibility ? "42" : nil
                $0.accessibilityHint = example == .accessibility ? "Use the Actions rotor to inspect this sample." : nil
                $0.accessibilityCustomActions = actions
                $0.accessibilityIdentifier = "label-" + example.rawValue
            }
        }
        return element.inset(uniform: 10).box(background: .secondarySystemBackground, corners: .rounded(radius: 8))
    }

    private func content(_ example: Example) -> NSAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = example == .center ? .center : (example == .right ? .right : .natural)
        paragraph.lineBreakMode = .byTruncatingTail
        paragraph.lineBreakStrategy = .pushOut
        let string: String
        switch example {
        case .links: string = "Read the Terms and Privacy policy. Long-press either link to inspect native menus in TextView."
        case .detected: string = "Call (415) 555-0123, visit 1455 Market St, San Francisco CA, open https://squareup.com, or meet January 15, 2030 at 10 AM."
        case .rtl: string = "שלום עולם. مرحباً بالعالم. Native paragraph direction and alignment."
        case .styled: string = "Bold, italic, colored, underlined, and struck text share one attributed string."
        case .fitting: string = "A long single line shrinks to fit its available width."
        case .updates: string = expandedContent ? String(repeating: "Updated content grows and wraps. ", count: 8) : "Short content. Tap Update text."
        case .header: string = "A heading with a native header trait."
        case .accessibility: string = "Visible content with a custom spoken label, value, hint, and action."
        case .hidden: string = "This visible specimen is intentionally skipped by VoiceOver."
        case .empty: string = ""
        default: string = "Body content wraps naturally at the available width. Increase Dynamic Type to compare line limits, baseline placement, and sizing."
        }
        let text = NSMutableAttributedString(
            string: string,
            attributes: [
                .font: UIFont.preferredFont(forTextStyle: example == .header ? .title2 : .body),
                .foregroundColor: UIColor.label,
                .paragraphStyle: paragraph,
            ]
        )
        func add(_ attributes: [NSAttributedString.Key: Any], to word: String) {
            let range = (string as NSString).range(of: word)
            if range.location != NSNotFound { text.addAttributes(attributes, range: range) }
        }
        if example == .links {
            add([.link: URL(string: "https://example.com/terms")!], to: "Terms")
            add([.link: URL(string: "https://example.com/privacy")!], to: "Privacy policy")
        }
        if example == .styled {
            let size = UIFont.preferredFont(forTextStyle: .body).pointSize
            add([.font: UIFont.boldSystemFont(ofSize: size)], to: "Bold")
            add([.font: UIFont.italicSystemFont(ofSize: size)], to: "italic")
            add([.foregroundColor: UIColor.systemRed, .backgroundColor: UIColor.systemYellow], to: "colored")
            add([.underlineStyle: NSUnderlineStyle.single.rawValue], to: "underlined")
            add([.strikethroughStyle: NSUnderlineStyle.single.rawValue], to: "struck")
        }
        return text
    }

    private func linkedText(_ string: String, word: String, url: String) -> NSAttributedString {
        let text = NSMutableAttributedString(
            string: string,
            attributes: [.font: UIFont.preferredFont(forTextStyle: .body), .foregroundColor: UIColor.label]
        )
        text.addAttribute(.link, value: URL(string: url)!, range: (string as NSString).range(of: word))
        return text
    }

    @available(iOS 17.0, *)
    private func listText(ordered: Bool) -> NSAttributedString {
        let list = NSTextList(markerFormat: ordered ? .decimal : .disc, options: 0)
        list.startingItemNumber = 9
        let nested = NSTextList(markerFormat: .disc, options: 0)
        let text = NSMutableAttributedString(string: "")
        for (item, lists) in [
            (
                "A wrapping item with enough text to grow at larger text sizes.\u{2028}The same item continues on this line.",
                [list]
            ),
            ("A nested item with a link to Block.", [list, nested]),
            ("The next parent item.", [list]),
        ] {
            let paragraph = NSMutableParagraphStyle()
            paragraph.textLists = lists
            paragraph.paragraphSpacing = 8
            text.append(NSAttributedString(
                string: item + "\n",
                attributes: [
                    .font: UIFont.preferredFont(forTextStyle: .body),
                    .foregroundColor: UIColor.label,
                    .paragraphStyle: paragraph,
                ]
            ))
        }
        text.deleteCharacters(in: NSRange(location: text.length - 1, length: 1))
        text.addAttribute(
            .link,
            value: URL(string: "https://block.xyz")!,
            range: (text.string as NSString).range(of: "Block")
        )
        return text
    }

    private func presentAlert(message: String) {
        let alert = UIAlertController(title: "Link or action", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .default))
        present(alert, animated: true)
    }
}
