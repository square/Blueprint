import BlueprintUI
import BlueprintUICommonControls

struct LineItemElement: ProxyElement {

    var style: Style
    var title: String
    var price: Double

    var elementRepresentation: Element {
        Row(underflow: .spaceEvenly) {
            Label(text: title) { label in
                label.font = style.titleFont
                label.color = style.titleColor
            }

            Label(text: formattedPrice) { label in
                label.font = style.priceFont
                label.color = style.priceColor
            }
        }
    }

    private var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: NSNumber(value: price)) ?? ""
    }

}

extension LineItemElement {

    enum Style {
        case regular
        case bold

        fileprivate var titleFont: UIFont {
            switch self {
            case .regular: return .systemFont(ofSize: 18.0)
            case .bold: return .boldSystemFont(ofSize: 18.0)
            }
        }

        fileprivate var titleColor: UIColor {
            switch self {
            case .regular: return .gray
            case .bold: return .black
            }
        }

        fileprivate var priceFont: UIFont {
            switch self {
            case .regular: return .systemFont(ofSize: 18.0)
            case .bold: return .boldSystemFont(ofSize: 18.0)
            }
        }

        fileprivate var priceColor: UIColor {
            switch self {
            case .regular: return .black
            case .bold: return .black
            }
        }

    }

}
