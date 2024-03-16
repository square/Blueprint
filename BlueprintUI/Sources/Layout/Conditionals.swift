extension Element {

    //
    // MARK: If / Else
    //

    /// Returns a new element from the provided `modify`
    /// closure, if the provided boolean is true. Otherwise, the original
    /// element is returned.
    /// ```
    /// myElement.if(someBoolean) { element in
    ///     element.centered()
    /// }
    /// ```
    public func `if`(
        _ isTrue: Bool,
        then: (Self) -> Element
    ) -> Element {
        if isTrue {
            return then(self)
        } else {
            return self
        }
    }

    /// Returns a new element from the provided `then`
    /// closure if the provided boolean is true. If the provided boolean
    /// is false, the `else` closure is used
    /// ```
    /// myElement.if(
    ///     someBoolean,
    ///     then: { element in
    ///           element.aligned(horizontally: .trailing, vertically: .fill)
    ///     },
    ///     else: { element in
    ///         element.aligned(horizontally: .leading, vertically: .fill)
    ///     }
    /// )
    /// ```
    public func `if`(
        _ isTrue: Bool,
        then: (Self) -> Element,
        else: (Self) -> Element
    ) -> Element {
        if isTrue {
            return then(self)
        } else {
            return `else`(self)
        }
    }

    //
    // MARK: If Let
    //

    /// Returns a new element from the provided `modify`
    /// closure if the provided value is non-nil. Otherwise, the original
    /// element is returned.
    /// ```
    /// myElement.if(let: someValue) { value, element in
    ///     element.inset(uniform: someValue.padding)
    /// }
    /// ```
    public func `if`<Value>(
        `let` value: Value?,
        then: (Value, Self) -> Element
    ) -> Element {
        if let value = value {
            return then(value, self)
        } else {
            return self
        }
    }

    /// Returns a new element from the provided `then`
    /// closure if the provided boolean is true. If the provided value
    /// is nil, the `else` closure is used
    /// ```
    /// myElement.if(
    ///     let: someValue,
    ///     then: { value, element in
    ///           element.inset(uniform: value.padding)
    ///     },
    ///     else: { element in
    ///         element.inset(uniform: 10)
    ///     }
    /// )
    /// ```
    public func `if`<Value>(
        `let` value: Value?,
        then: (Value, Self) -> Element,
        else: (Self) -> Element
    ) -> Element {
        if let value = value {
            return then(value, self)
        } else {
            return `else`(self)
        }
    }

    //
    // MARK: Map & Modify
    //

    /// Creates and returns a new element by passing the
    /// element to the provided `map` function.
    ///
    /// ```
    /// myElement.map { element in
    ///     switch myState {
    ///     case .small: element.inset(uniform: 5)
    ///     case .medium: element.inset(uniform: 10)
    ///     case .large: element.inset(uniform: 15)
    ///     }
    /// }
    /// ```
    public func map(_ map: (Self) -> Element) -> Element {
        map(self)
    }

    /// Creates and returns a new element by passing the
    /// element to the provided `modify` function, which can edit it.
    ///
    /// ```
    /// myElement.modify { element in
    ///     switch myState {
    ///     case .small: element.inset = 5
    ///     case .medium: element.inset = 10
    ///     case .large: element.inset = 15
    ///     }
    /// }
    /// ```
    public func modify(_ modify: (inout Self) -> Void) -> Element {
        var copy = self
        modify(&copy)
        return copy
    }
}
