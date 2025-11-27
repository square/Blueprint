# Blueprint

[![Tests](https://github.com/square/Blueprint/actions/workflows/tests.yaml/badge.svg)](https://github.com/square/Blueprint/actions/workflows/tests.yaml)
[![Generate and publish docs](https://github.com/square/Blueprint/actions/workflows/docs.yml/badge.svg)](https://github.com/square/Blueprint/actions/workflows/docs.yml)
[![Linter](https://github.com/square/Blueprint/actions/workflows/lint.yml/badge.svg)](https://github.com/square/Blueprint/actions/workflows/lint.yml)

## Declarative UI construction for iOS, written in Swift

Blueprint greatly simplifies the task of building and updating views as application state changes.

```swift
let view = BlueprintView(element: Label(text: "Hello from Blueprint!"))
```

### What does this library do?

Blueprint provides an architecture that allows you to:
- Declaratively define a UI hierarchy as pure values (Swift structs and enums).
- Display that hierarchy within your application.
- Update that hierarchy as application state changes (including animated transitions).

### When should I use it?

Use Blueprint any time you want to display a view hierarchy, but don't want to manage view lifecycle (hint: managing view lifecycle is a large portion of most conventional UIKit code). There are times when you *want* to manage view lifecycle (complex animations and transitions are a good example), and for these cases you may want to stick with a conventional approach.

### How does it interact with UIKit?

Blueprint is not a replacement for UIKit! From the beginning, Blueprint has been designed as a compliment to all of the powerful tools that come with the platform. You can use Blueprint to manage the display of a single view controller, or of a single view representing a small part of the screen. Likewise, it's straightforward to host standard views and controls *within* a blueprint hierarchy, always leaving you with an escape hatch.

### How does it interact with SwiftUI?

They serve similar purposes, and SwiftUI has heavily influenced Blueprint's API. However, Blueprint predates SwiftUI, and works a bit differently. You can host a `BlueprintView` in SwiftUI to embed Blueprint within SwiftUI, and you can also use the provided `ElementView` to create Xcode previews of Blueprint. Because SwiftUI is hosted by a UIViewController, and Blueprint is hosted in a UIView, we don't provide a way to embed SwiftUI within Blueprint.

## Getting Started

### Swift Package Manager

[![SwiftPM compatible](https://img.shields.io/badge/SwiftPM-compatible-orange.svg)](#swift-package-manager)

If you are developing your own package, be sure that Blueprint is included in `dependencies`
in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/square/Blueprint", from: "5.1.0")
]
```

In Xcode 11+, add Blueprint directly as a dependency to your project with
`File` > `Swift Packages` > `Add Package Dependency...`. Provide the git URL when prompted: `git@github.com:square/Blueprint.git`.

Three modules are provided:
- `BlueprintUI` contains the core architecture and layout types.
- `BlueprintUICommonControls` includes elements representing some common `UIKit` views and controls.
- `BlueprintUIAccessibilityCore` provides accessibility infrastructure for component authors.

## Documentation

API documentation is available at [square.github.io/Blueprint](https://square.github.io/Blueprint/)

### Getting Started

1.  **[Hello, World](Documentation/GettingStarted/HelloWorld.md)**

1.  **[The Element Hierarchy](Documentation/GettingStarted/ElementHierarchy.md)**

1.  **[Building Custom Elements](Documentation/GettingStarted/CustomElements.md)**

1.  **[Layout](Documentation/GettingStarted/Layout.md)**


### Reference

1.  **[`Element`](Documentation/Reference/Element.md)**

1.  **[`BlueprintView`](Documentation/Reference/BlueprintView.md)**

1.  **[`ViewDescription`](Documentation/Reference/ViewDescription.md)**

1.  **[Transitions](Documentation/Reference/Transitions.md)**


### Tutorials

[Tutorial setup instructions](Documentation/Tutorials/Setup.md)

1. **[Using Blueprint in a View Controller](Documentation/Tutorials/Tutorial1.md)**

1. **[Building a receipt layout with Blueprint](Documentation/Tutorials/Tutorial2.md)**

## Local Development

This project uses [Mise](https://mise.jdx.dev/) and [Tuist](https://tuist.io/) to generate a project for local development. Follow the steps below for the recommended setup for zsh.

```sh
# install mise
brew install mise
# add mise activation line to your zshrc
echo 'eval "$(mise activate zsh)"' >> ~/.zshrc
# load mise into your shell
source ~/.zshrc
# tell mise to trust Blueprint's config file
mise trust
# install dependencies
mise install

# only necessary for first setup or after changing dependencies
tuist install --path SampleApp
# generates and opens the Xcode project
tuist generate --path SampleApp
```

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
