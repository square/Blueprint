import Blueprint
import BlueprintCommonControls

struct LineItemElement: ProxyElement {

    var style: Style
    var title: String
    var price: Double

    var elementRepresentation: Element {
        return Row { row in

            row.horizontalUnderflow = .spaceEvenly

            var titleLabel = Label(text: title)
            titleLabel.font = style.titleFont
            titleLabel.color = style.titleColor
            row.add(child: titleLabel)

            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            let formattedPrice = formatter.string(from: NSNumber(value: price)) ?? ""

            var priceLabel = Label(text: formattedPrice)
            priceLabel.font = style.priceFont
            priceLabel.color = style.priceColor
            row.add(child: priceLabel)

        }
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
