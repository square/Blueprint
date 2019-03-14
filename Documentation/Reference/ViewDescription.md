# `ViewDescription`

View Descriptions contain all the information needed to create an instance of a native UIView. **Importantly, view desctiptions do not contain *instances* of a view**. They only contain the data necessary to instantiate or update a view.

## Creating a view description

```swift
let description = UILabel.describe { config in
    config[\.text] = "Hello, world"
    config[\.textColor] = .orange
}

// Or...

let description = ViewDescription(UILabel.self) { config in
    config[\.text] = "Hello, world"
    config[\.textColor] = .orange
}
```

In both cases, the last argument is a closure responsible for configuring the view type. The argument passed into the closure is a value of the type `ViewDescription.Configuration`

```swift
extension ViewDescription {
    public struct Configuration<View: UIView> {}
}
```

### Specifying how the view should be instantiated

```swift
let description = UITableView.describe { config in
    config.builder = { UITableView(frame: .zero, style: .plain) }
}
```

### Assigning values to properties

```swift
let description = UIView.describe { config in
    config[\.backgroundColor] = .magenta
}
```

### Applying arbitrary update logic

```swift
let description = UIView.describe { config in
    config.apply { view in
        view.layer.masksToBounds = true
    }
}
```

### Specifying a subview that should contain any view-backed child elements

```swift
let description = MyCustomView.describe { config in
    config.contentView = { $0.childContainerView }
}
```

### Specifying transitions

```swift
let description = UIView.describe { config in
    config.layoutTransition = .specific(AnimationAttributes())
    config.appearingTransition = .scale
    config.disappearingTransition = .fade
}
```

