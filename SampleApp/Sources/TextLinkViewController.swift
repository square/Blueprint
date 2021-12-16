import BlueprintUI
import BlueprintUICommonControls
import UIKit

final class TextLinkViewController: UIViewController {

    private let blueprintView = BlueprintView()

    override func loadView() {
        view = blueprintView
        blueprintView.element = element
    }

    var element: Element {
        let text = "This is an attributed string with a phone number, address, link, and date. The phone number is (555) 555-5555. The address is 1455 Market St, San Francisco CA. The link is https://squareup.com. And the date is 12/1/21. There's also a `link` attribute to Block right here!"
        let linkRange = text.range(of: "right here")!
        let attributedText = NSMutableAttributedString(string: text)
        attributedText.addAttribute(.link, value: "https://block.xyz", range: NSRange(linkRange, in: text))

        let label = AttributedLabel(attributedText: attributedText) {
            $0.linkDetectionTypes = [.link, .phoneNumber, .address, .date]
        }

        let centered = NSMutableParagraphStyle()
        centered.alignment = NSTextAlignment.center

        let right = NSMutableParagraphStyle()
        right.alignment = NSTextAlignment.right

        let justified = NSMutableParagraphStyle()
        justified.alignment = NSTextAlignment.justified

        return Column(alignment: .fill, minimumSpacing: 20) {
            label
            Label(text: "Custom link handling:")
            label.onLinkTapped {
                self.presentAlert(message: $0.absoluteString)
            }

            AttributedLabel(attributedText: NSAttributedString(string: "https://squareup.com")) {
                $0.linkDetectionTypes = [.link]
            }

            AttributedLabel(attributedText: NSAttributedString(
                string: "https://squareup.com",
                attributes: [.paragraphStyle: centered]
            )) {
                $0.linkDetectionTypes = [.link]
            }

            AttributedLabel(attributedText: NSAttributedString(
                string: "https://squareup.com",
                attributes: [.paragraphStyle: right]
            )) {
                $0.linkDetectionTypes = [.link]
            }
        }
        .inset(uniform: 20)
        .centered()
    }

    func presentAlert(message: String) {
        let alert = UIAlertController(title: "Tapped a link", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
