# BlueprintUIAccessibilityCore

This module provides accessibility infrastructure for Blueprint UI component authors. It focuses on **accessibility composition** and **accessibility deferral** patterns for creating sophisticated, reusable accessible components.

**Note**: This module is primarily intended for component library development. Most feature development should use Blueprint's standard accessibility modifiers instead.

## Core Features

### Accessibility Composition
Combine multiple accessibility elements into a unified experience:
- Smart element merging of labels, values, hints, and traits
- Preserve interactive functionality while combining content
- Consolidate custom actions from multiple sources
- Combine and sequence accessibility rotors

### Accessibility Deferral
Pass accessibility content from container elements to their children:
- Content inheritance from parent to child elements
- Specialized error handling for form validation
- Conditional exposure based on element hierarchy
- Support for AXCustomContent and accessibility rotors

## When to Use

### ✅ Use AccessibilityComposition when:
- Building complex UI components with multiple sub-elements
- Creating custom controls that need unified accessibility representation
- Combining interactive and non-interactive elements (e.g., label + switch)
- Need to preserve individual element functionality while providing combined context

### ✅ Use AccessibilityDeferral when:
- Building form fields where error/helper text should be associated with input elements
- Creating container components that provide context to child elements
- Need to conditionally show/hide accessibility content based on hierarchy
- Want child elements to announce parent-provided information

## Getting Started

### 1. Add the Dependency

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/square/Blueprint", from: "1.0.0")
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: [
            .product(name: "BlueprintUI", package: "Blueprint"),
            .product(name: "BlueprintUIAccessibilityCore", package: "Blueprint"),
        ]
    ),
]
```

### 2. Import the Module

```swift
import BlueprintUI
import BlueprintUIAccessibilityCore
```

## Accessibility Composition

### Basic Usage

Use `AccessibilityComposition.CombinableView` to automatically combine child accessibility elements:

```swift
let combinableView = AccessibilityComposition.CombinableView()
combinableView.addSubview(titleLabel)
combinableView.addSubview(valueLabel) 
combinableView.addSubview(actionButton)

// The view automatically combines:
// - Labels: "Title, Value"
// - Actions: Button functionality preserved
// - Traits: Inherits button traits
// - Custom actions: All actions available in rotor
```

### Custom Filtering and Sorting

```swift
let combinableView = AccessibilityComposition.CombinableView()

// Filter which elements to include
combinableView.customFilter = { element in
    // Only include visible, non-decorative elements
    return !element.accessibilityElementsHidden && 
           element.hasAccessibilityRepresentation
}

// Custom sorting (default uses frame-based sorting)
combinableView.customSorting = { element1, element2 in
    // Sort by semantic importance rather than visual position
    return element1.accessibilityTraits.contains(.header)
}
```

### Override Combined Values

```swift
let combinableView = AccessibilityComposition.CombinableView()

// Override the computed combination
combinableView.overrideValues = AccessibilityComposition.CompositeRepresentation(
    [], 
    invalidator: { /* update callback */ }
)
combinableView.overrideValues?.label = "Custom combined label"
combinableView.overrideValues?.traits = .button
```

## Accessibility Deferral

### Basic Form Field Example

```swift
// 1. Create content to defer
let errorContent = AccessibilityDeferral.Content(
    kind: .error,
    identifier: "field-error"
)

// 2. Wrap your form field with deferral container
let formField = Column {
    TextField(text: $text)
        .accessibilityDeferralReceiver() // Receives deferred content
    
    if hasError {
        Text("Invalid input")
            .deferredAccessibilitySource(identifier: "field-error") // Source of content
    }
}
.deferAccessibilityToChildren(content: [errorContent])
```

### Custom Content Deferral

```swift
// Create custom accessibility content
let helperContent = AccessibilityDeferral.Content(
    kind: .custom(Accessibility.CustomContent(
        label: "Helper",
        value: "This field accepts email addresses",
        importance: .default
    )),
    identifier: "field-helper"
)

let formField = Column {
    TextField(text: $email)
        .accessibilityDeferralReceiver()
    
    Text("Enter your email address")
        .deferredAccessibilitySource(identifier: "field-helper")
}
.deferAccessibilityToChildren(content: [helperContent])
```

### Implementing Custom Receivers

```swift
class CustomTextField: UITextField, AccessibilityDeferral.Receiver {
    var rotorSequencer: AccessibilityComposition.RotorSequencer?
    var customContent: [Accessibility.CustomContent]?
    var deferredAccessibilityContent: [AccessibilityDeferral.Content]?
    
    // Default implementation provided by protocol extension
    // Override if you need custom behavior
}
```

## Advanced Features

### Rotor Sequencing

The `RotorSequencer` automatically handles multiple rotors of the same system type:

```swift
// Multiple heading rotors are combined into a single rotor
// that cycles through results from all sources
let rotor1 = UIAccessibilityCustomRotor(systemType: .heading) { /* ... */ }
let rotor2 = UIAccessibilityCustomRotor(systemType: .heading) { /* ... */ }

let sequencer = AccessibilityComposition.RotorSequencer(rotors: [rotor1, rotor2])
// Results in a single .heading rotor that searches both sources
```

### Interactive Element Merging

```swift
let combinableView = AccessibilityComposition.CombinableView()

// When enabled (default), single interactive children are merged
// into the parent's accessibility representation
combinableView.mergeInteractiveSingleChild = true

// Result: "Label: On" with button traits and toggle functionality
// Instead of: Label + separate button action
```

### Custom Interactions

```swift
let combinableView = AccessibilityComposition.CombinableView()

combinableView.accessibilityInteractions = AccessibilityComposition.Interactions(
    activationPoint: CGPoint(x: 100, y: 50),
    activate: { 
        // Custom activation logic
        return true 
    },
    increment: { /* increment logic */ },
    decrement: { /* decrement logic */ }
)
```

## Best Practices

### ✅ Do
- Test with VoiceOver to verify combined accessibility makes sense
- Use semantic ordering (reading flow) rather than visual ordering when needed
- Provide meaningful labels for combined elements
- Test deferral patterns to ensure content appears in the right place
- Use error deferral for form validation feedback

### ❌ Don't
- Over-combine elements that should remain separate for clarity
- Create confusing navigation patterns by hiding too many interactive elements
- Forget to test with assistive technologies
- Use deferral when simple parent-child relationships would work better

## Localization

The module includes localized strings for:
- Error labels (`"Error"`)
- Increment/decrement actions
- Toggle button states (`"On"`, `"Off"`, `"Mixed"`)

Strings are automatically localized based on the user's system language.

## Testing

Key areas to test:

1. **VoiceOver Navigation** - Ensure combined elements read logically
2. **Custom Actions** - Verify all actions are accessible via rotor
3. **Rotor Functionality** - Test that rotors work correctly when combined
4. **Deferral Behavior** - Confirm content appears on intended receivers
5. **Error Announcements** - Verify error content is properly announced

## Integration with Blueprint Elements

Both composition and deferral work seamlessly with Blueprint's element system:

```swift
struct CustomFormField: Element {
    var content: ElementContent {
        // Deferral happens at the Element level
        Column {
            TextField(...)
            if showError {
                ErrorLabel(...)
            }
        }
        .deferAccessibilityToChildren(content: errorContent)
    }
    
    func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        // Composition happens at the View level
        AccessibilityComposition.CombinableView.describe { config in
            config[\.mergeInteractiveSingleChild] = true
        }
    }
}
```

This module provides the foundation for creating accessible, complex UI components in Blueprint while maintaining excellent assistive technology support.
