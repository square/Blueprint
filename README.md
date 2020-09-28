[![Build Status](https://travis-ci.com/square/Blueprint.svg?branch=master)](https://travis-ci.com/square/Blueprint)

# Blueprint

### Declarative UI construction for iOS, written in Swift

Blueprint greatly simplifies the task of building and updating views as application state changes.

*We still consider Blueprint experimental (and subject to major breaking API changes), but it has been used within Square's production iOS apps.*

```swift
let rootElement = Label(text: "Hello from Blueprint!")
let view = BlueprintView(element: rootElement)
```

Generated documentation is available at [square.github.io/Blueprint](https://square.github.io/Blueprint/)

### Getting Started

#### Swift Package Manager

[![SwiftPM compatible](https://img.shields.io/badge/SwiftPM-compatible-orange.svg)](#swift-package-manager)

If you are developing your own package, be sure that Blueprint is included in `dependencies`
in `Package.swift`:

```swift
dependencies: [
    .package(url: "git@github.com:square/Blueprint.git", from: "0.3.0")
]
```

In Xcode 11+, add Blueprint directly as a dependency to your project with
`File` > `Swift Packages` > `Add Package Dependency...`. Provide the git URL when prompted: `git@github.com:square/Blueprint.git`.

#### Cocoapods

[![CocoaPods compatible](https://img.shields.io/cocoapods/v/BlueprintUI.svg)](https://cocoapods.org/pods/BlueprintUI)

If you use CocoaPods to manage your dependencies, simply add BlueprintUI and BlueprintUICommonControls to your
Podfile:

```ruby
pod 'BlueprintUI'
pod 'BlueprintUICommonControls'
```

---

##### What does this library do?

Blueprint provides an architecture that allows you to:
- Declaratively define a UI hierarchy as pure values (Swift structs and enums).
- Display that hierarchy within your application.
- Update that hierarchy as application state changes (including animated transitions).

##### When should I use it?

Use Blueprint any time you want to display a view hierarchy, but don't want to manage view lifecycle (hint: managing view lifecycle is a large portion of most conventional UIKit code). There are times when you *want* to manage view lifecycle (complex animations and transitions are a good example), and for these cases you may want to stick with a conventional approach.

##### How does it interact with `UIKit`?

Blueprint is not a replacement for UIKit! From the beginning, Blueprint has been designed as a compliment to all of the powerful tools that come with the platform. You can use Blueprint to manage the display of a single view controller, or of a single view representing a small part of the screen. Likewise, it's straightforward to host standard views and controls *within* a blueprint hierarchy, always leaving you with an escape hatch.

---

## Documentation

#### Getting Started

1.  **[Hello, World](Documentation/GettingStarted/HelloWorld.md)**

1.  **[The Element Hierarchy](Documentation/GettingStarted/ElementHierarchy.md)**

1.  **[Building Custom Elements](Documentation/GettingStarted/CustomElements.md)**

1.  **[Layout](Documentation/GettingStarted/Layout.md)**


#### Reference

1.  **[`Element`](Documentation/Reference/Element.md)**

1.  **[`BlueprintView`](Documentation/Reference/BlueprintView.md)**

1.  **[`ViewDescription`](Documentation/Reference/ViewDescription.md)**

1.  **[Transitions](Documentation/Reference/Transitions.md)**


#### Tutorials

[Tutorial setup instructions](Documentation/Tutorials/Setup.md)

1. **[Using Blueprint in a View Controller](Documentation/Tutorials/Tutorial1.md)**

1. **[Building a receipt layout with Blueprint](Documentation/Tutorials/Tutorial2.md)**

---

## Adding Blueprint to an existing project

Two modules are provided:
- **`BlueprintUI`** contains the core architecture and layout types.
- **`BlueprintUICommonControls`** includes elements representing some common `UIKit` views and controls.

Blueprint is available via CocoaPods. Add it to your `Podfile` to integrate:

```ruby
target MyTarget do
    pod 'BlueprintUI'
    pod 'BlueprintUICommonControls'
end
```

---

[Release instructions](./RELEASING.md)

---

Copyright 2019 Square, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
