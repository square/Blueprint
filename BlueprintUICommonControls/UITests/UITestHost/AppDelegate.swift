import BlueprintUI
import BlueprintUICommonControls
import UIKit

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = UIViewController()
        if #available(iOS 17.0, *), ProcessInfo.processInfo.arguments.contains("-attributed-text-view") {
            window?.rootViewController = AttributedTextViewTestController()
        }
        window?.makeKeyAndVisible()

        return true
    }

}

@available(iOS 17.0, *)
private final class AttributedTextViewTestController: UIViewController, UITextViewDelegate {
    private let blueprint = BlueprintView()
    private let result = UILabel()
    private var handler = 1
    private var detectsLinks = ProcessInfo.processInfo.arguments.contains("-detect-links")

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        result.accessibilityIdentifier = "result"
        result.numberOfLines = 0
        result.text = "Ready"
        result.frame = CGRect(x: 20, y: 80, width: 300, height: 70)
        view.addSubview(result)
        blueprint.frame = CGRect(x: 20, y: 160, width: 300, height: 120)
        view.addSubview(blueprint)
        for (index, title) in ["Replace handler", "Disable detection", "Activate accessibility"].enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.frame = CGRect(x: 20, y: CGFloat(300 + index * 60), width: 300, height: 44)
            button.addAction(UIAction { [weak self] _ in
                guard let self else { return }
                if index == 2 {
                    activateAccessibility()
                    return
                }
                if index == 0 { handler += 1 } else { detectsLinks = false }
                update()
            }, for: .touchUpInside)
            view.addSubview(button)
        }
        update()
    }

    private func activateAccessibility() {
        func find(in view: UIView, matching: (UIView) -> Bool) -> UIView? {
            if matching(view) { return view }
            for child in view.subviews {
                if let match = find(in: child, matching: matching) { return match }
            }
            return nil
        }
        guard let target = find(in: view, matching: { $0.accessibilityIdentifier == "composed" }) else { return }
        if !target.accessibilityActivate() {
            result.text = "Native fallback; link=\(target.accessibilityTraits.contains(.link)); header=\(target.accessibilityTraits.contains(.header))"
        }
    }

    private func update() {
        let detectionCase = ProcessInfo.processInfo.arguments.contains("-detect-links")
        let detectsDate = ProcessInfo.processInfo.arguments.contains("-detect-dates")
        let text = NSMutableAttributedString(
            string: detectionCase
                ? "Terms " + (detectsDate ? "January 15, 2030 at 10 AM" : "https://example.com/detected")
                : "Terms Privacy",
            attributes: [.font: UIFont.systemFont(ofSize: 20), .foregroundColor: UIColor.label]
        )
        if ProcessInfo.processInfo.arguments.contains("-single-link") {
            text.mutableString.setString("Terms")
        }
        if ProcessInfo.processInfo.arguments.contains("-native-list") {
            let paragraph = NSMutableParagraphStyle()
            paragraph.textLists = [NSTextList(markerFormat: .disc, options: 0)]
            text.setAttributedString(NSAttributedString(
                string: "First item\nSecond item\nThird item",
                attributes: [.font: UIFont.systemFont(ofSize: 20), .paragraphStyle: paragraph]
            ))
        }
        for title in detectionCase ? ["Terms"] : ["Terms", "Privacy"] {
            let range = (text.string as NSString).range(of: title)
            guard range.location != NSNotFound else { continue }
            text.addAttribute(
                .link,
                value: URL(string: "https://example.com/" + title.lowercased())!,
                range: range
            )
        }
        if ProcessInfo.processInfo.arguments.contains("-uikit-reference") {
            let native = UITextView(usingTextLayoutManager: true)
            native.isEditable = false
            native.isScrollEnabled = false
            native.textContainerInset = .zero
            native.textContainer.lineFragmentPadding = 0
            native.delegate = self
            native.isSelectable = false
            native.dataDetectorTypes = []
            native.linkTextAttributes = [.foregroundColor: UIColor.link]
            let paragraph = NSMutableParagraphStyle()
            paragraph.lineBreakMode = .byWordWrapping
            text.addAttribute(.paragraphStyle, value: paragraph, range: NSRange(location: 0, length: text.length))
            native.attributedText = text
            native.accessibilityIdentifier = "composed"
            native.frame = CGRect(origin: blueprint.frame.origin, size: native.sizeThatFits(blueprint.bounds.size))
            if ProcessInfo.processInfo.arguments.contains("-heading") {
                native.accessibilityTraits.formUnion([.header, .staticText])
            }
            view.addSubview(native)
            blueprint.isHidden = true
            return
        }
        let currentHandler = handler
        let element = AttributedTextView(attributedText: text) {
            $0.isSelectable = detectionCase
            if ProcessInfo.processInfo.arguments.contains("-label-role") {
                $0.textAccessibilityRole = .label
            }
            if ProcessInfo.processInfo.arguments.contains("-explicit-value") {
                $0.accessibilityValue = "42 dollars"
                $0.isAccessibilityElement = true
            }
            if ProcessInfo.processInfo.arguments.contains("-heading") { $0.accessibilityTraits = [.header, .staticText] }
            $0.linkDetectionTypes = detectsLinks ? [detectsDate ? .date : .link] : []
        }.onLinkTapped { [weak self] url in
            self?.result.text = "Handler \(currentHandler): \(url.absoluteString)"
        }
        blueprint.element = ProcessInfo.processInfo.arguments.contains("-combine")
            ? element.accessibility(identifier: "composed") : element
    }

    func textView(_ textView: UITextView, primaryActionFor textItem: UITextItem, defaultAction: UIAction) -> UIAction? {
        guard case .link(let url) = textItem.content else { return defaultAction }
        return UIAction { [weak self] _ in
            guard let self else { return }
            result.text = "Handler \(handler): \(url.absoluteString)"
        }
    }

    func textView(_ textView: UITextView, menuConfigurationFor textItem: UITextItem, defaultMenu: UIMenu) -> UITextItem.MenuConfiguration? {
        .init(menu: defaultMenu)
    }

}

