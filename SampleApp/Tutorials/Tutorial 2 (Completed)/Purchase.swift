struct Purchase {

    var items: [Item]

    var subtotal: Double {
        return items
            .map { $0.price }
            .reduce(0.0, +)
    }

    var tax: Double {
        return subtotal * 0.085
    }

    var total: Double {
        return subtotal + tax
    }

    struct Item {
        var name: String
        var price: Double
    }

    static var sample: Purchase {
        return Purchase(items: [
            Item(name: "Burger", price: 7.99),
            Item(name: "Fries", price: 2.49),
            Item(name: "Soda", price: 1.49)
        ])
    }

}
