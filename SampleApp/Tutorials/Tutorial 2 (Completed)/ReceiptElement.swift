import BlueprintUI
import BlueprintUICommonControls


struct ReceiptElement: ProxyElement {

    let purchase = Purchase.sample

    var elementRepresentation: Element {
        let column = Column { col in
            col.minimumVerticalSpacing = 16.0
            col.horizontalAlignment = .fill

            for item in purchase.items {
                col.add(
                    child: LineItemElement(
                        style: .regular,
                        title: item.name,
                        price: item.price))
            }

            // Add a rule below all of the line items
            col.add(child: RuleElement())

            // Totals
            col.add(
                child: LineItemElement(
                    style: .regular,
                    title: "Subtotal",
                    price: purchase.subtotal))


            col.add(
                child: LineItemElement(
                    style: .regular,
                    title: "Tax",
                    price: purchase.tax))

            col.add(
                child: LineItemElement(
                    style: .bold,
                    title: "Total",
                    price: purchase.total))
        }

        let inset = Inset(
            wrapping: column,
            uniformInset: 24.0)

        var scrollView = ScrollView(wrapping: inset)
        scrollView.contentSize = .fittingHeight
        scrollView.alwaysBounceVertical = true
        return scrollView
    }

}
