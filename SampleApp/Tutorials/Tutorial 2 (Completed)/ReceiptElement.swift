import BlueprintUI
import BlueprintUICommonControls


struct ReceiptElement: ProxyElement {

    let purchase = Purchase.sample

    var elementRepresentation: Element {
        Column(alignment: .fill, minimumSpacing: 16) {
            for item in purchase.items {
                LineItemElement(
                    style: .regular,
                    title: item.name,
                    price: item.price
                )
            }

            // Add a rule below all of the line items
            RuleElement()

            // Totals
            LineItemElement(
                style: .regular,
                title: "Subtotal",
                price: purchase.subtotal
            )

            LineItemElement(
                style: .regular,
                title: "Tax",
                price: purchase.tax
            )

            LineItemElement(
                style: .bold,
                title: "Total",
                price: purchase.total
            )
        }
        .inset(uniform: 24)
        .scrollable { scrollView in
            scrollView.alwaysBounceVertical = true
        }
    }

}
