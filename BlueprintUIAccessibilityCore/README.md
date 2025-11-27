# BlueprintUIAccessibilityCore

This module provides accessibility infrastructure for Blueprint UI component authors. It focuses on **accessibility composition** and **accessibility deferral** patterns for creating complex accessible UI components in Blueprint

**Note**: This module is primarily intended for component library development. Most feature development should use Blueprint's accessibility modifiers instead.

## Core Features

### Accessibility Deferral
Pass accessibility content from container elements to their children:
- Content inheritance from parent to child elements
- Specialized error handling for form validation
- Conditional exposure based on element hierarchy
- Support for AXCustomContent and accessibility rotors

### Accessibility Composition
Combine multiple accessibility elements into a unified experience:
- Smart element merging of labels, values, hints, and traits
- Preserve interactive functionality while combining content
- Consolidate custom actions from multiple sources
- Combine and sequence accessibility rotors


## When to Use

### ✅ Use AccessibilityDeferral when:
- Building form fields where error/helper text should be associated with input elements
- Creating container components that provide context to child elements
- Need to conditionally show/hide accessibility content based on hierarchy
- Want child elements to announce parent-provided information

### ✅ Use AccessibilityComposition when:
- Building complex UI components with multiple sub-elements
- Creating custom controls that need unified accessibility representation
- Combining interactive and non-interactive elements (e.g., label + switch)
- Need to preserve individual element functionality while providing combined context

## Accessibility Deferral

### Basic Form Field Example

```swift
struct FormFieldExample: Element {
    @State var text: String = ""
    @State var hasError: Bool = false

    var content: ElementContent {
        // 1. Create content to defer
        let errorContent = AccessibilityDeferral.Content(
            kind: .error,
            identifier: "field-error"
        )
        
        // 2. Wrap your form field with deferral container
        return Column {
            TextField(text: $text)
                // TextField needs to conform to AccessibilityDeferral.Receiver
            
            if hasError {
                Text("Invalid input")
                    .deferredAccessibilitySource(identifier: "field-error")
            }
        }
        .deferAccessibilityToChildren(content: [errorContent])
    }
}
```

### Implementing Custom Receivers

To make your custom views work with accessibility deferral:

```swift
class CustomTextField: UITextField, AccessibilityDeferral.Receiver {
    public var rotorSequencer: AccessibilityComposition.RotorSequencer?
    public var customContent: [Accessibility.CustomContent]?
    public var deferredAccessibilityContent: [AccessibilityDeferral.Content]?

    public override var accessibilityCustomRotors: [UIAccessibilityCustomRotor]? {
        get { super.accessibilityCustomRotors + rotorSequencer?.rotors }
        set { super.accessibilityCustomRotors = newValue }
    }

    public var accessibilityCustomContent: [AXCustomContent]! {
        get {
            let deferred = deferredAccessibilityContent?.compactMap { $0.customContent }
            let applied = customContent?.map { AXCustomContent($0) }
            return (applied + deferred)?.removingDuplicates ?? []
        }
        set { fatalError("Please set customContent var instead.") }
    }
}
```

## Implementing AccessibilityCombinable

For advanced use cases, you can implement the `AccessibilityCombinable` protocol directly in your custom views. This protocol provides the foundation for accessibility composition functionality.

### Protocol Requirements

```swift
public protocol AccessibilityCombinable: NSObject, UIAccessibilityIdentification, AXCustomContentProvider {
    var needsAccessibilityUpdate: Bool { get set }
    var rotorSequencer: AccessibilityComposition.RotorSequencer? { get set }
    var accessibilityInteractions: AccessibilityComposition.Interactions? { get set }
}
```

### Basic Implementation

```swift
class CustomCombinableView: UIView, AccessibilityCombinable {
    // Required protocol properties
    var needsAccessibilityUpdate = false
    var rotorSequencer: AccessibilityComposition.RotorSequencer?
    var accessibilityInteractions: AccessibilityComposition.Interactions?
    
    // Required by AXCustomContentProvider
    var accessibilityCustomContent: [AXCustomContent]! = []
    
    // Custom configuration
    var mergeInteractiveSingleChild = true
    var customFilter: AccessibilityComposition.Filter?
    var customSorting: AccessibilityComposition.Sorting?
    
    override var accessibilityLabel: String? {
        get {
            updateAccessibilityIfNeeded()
            return super.accessibilityLabel
        }
        set { super.accessibilityLabel = newValue }
    }
    
    override var accessibilityValue: String? {
        get {
            updateAccessibilityIfNeeded()
            return super.accessibilityValue
        }
        set { super.accessibilityValue = newValue }
    }
    
    // Implement similar getters for other accessibility properties...
    
    private func updateAccessibilityIfNeeded() {
        guard needsAccessibilityUpdate else { return }
        
        let combined = combineChildren(
            filter: customFilter,
            sorting: customSorting
        )
        
        applyAccessibility(combined, mergeInteractiveSingleChild: mergeInteractiveSingleChild)
    }
    
    // Override accessibility interaction methods
    override func accessibilityActivate() -> Bool {
        if let action = accessibilityInteractions?.activate {
            let result = action()
            if result {
                needsAccessibilityUpdate = true
                updateAccessibilityIfNeeded()
            }
            return result
        }
        return super.accessibilityActivate()
    }
    
    override func accessibilityIncrement() {
        if let action = accessibilityInteractions?.increment {
            action()
            needsAccessibilityUpdate = true
            updateAccessibilityIfNeeded()
        } else {
            super.accessibilityIncrement()
        }
    }
    
    override func accessibilityDecrement() {
        if let action = accessibilityInteractions?.decrement {
            action()
            needsAccessibilityUpdate = true
            updateAccessibilityIfNeeded()
        } else {
            super.accessibilityDecrement()
        }
    }
}
```

### Using with Blueprint Elements

```swift
struct CustomCombinableElement: Element {
    var mergeInteractive = true
    var filterHidden = true
    
    func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        CustomCombinableView.describe { config in
            config[\.mergeInteractiveSingleChild] = mergeInteractive
            config[\.customFilter] = filterHidden ? { element in
                !element.accessibilityElementsHidden
            } : nil
        }
    }
}
```

### Advanced Customization

```swift
class AdvancedCombinableView: UIView, AccessibilityCombinable {
    // Protocol requirements...
    var needsAccessibilityUpdate = false
    var rotorSequencer: AccessibilityComposition.RotorSequencer?
    var accessibilityInteractions: AccessibilityComposition.Interactions?
    var accessibilityCustomContent: [AXCustomContent]! = []
    
    // Custom override values
    var overrideValues: AccessibilityComposition.CompositeRepresentation?
    
    // Custom traits adjustment
    var traitsAdjust: (AccessibilityCombinable) -> Void = { _ in }
    
    private func updateAccessibilityIfNeeded() {
        guard needsAccessibilityUpdate else { return }
        
        // Use override values if provided, otherwise combine children
        let representation = overrideValues ?? combineChildren(
            filter: { element in
                // Custom filtering logic
                return !element.accessibilityElementsHidden && element.isAccessibilityElement
            },
            sorting: { element1, element2 in
                // Custom sorting logic - headers first, then reading order
                let element1IsHeader = element1.accessibilityTraits.contains(.header)
                let element2IsHeader = element2.accessibilityTraits.contains(.header)
                
                if element1IsHeader != element2IsHeader {
                    return element1IsHeader
                }
                
                // Fall back to visual order for same-priority elements
                if let view1 = element1 as? UIView, let view2 = element2 as? UIView {
                    return view1.frame.minY < view2.frame.minY
                }
                
                return false
            }
        )
        
        applyAccessibility(representation, mergeInteractiveSingleChild: true)
        
        // Apply custom traits adjustment
        traitsAdjust(self)
    }
    
    // Custom activation point for better touch targeting
    override var accessibilityActivationPoint: CGPoint {
        get {
            if let customPoint = accessibilityInteractions?.activationPoint {
                return convert(customPoint, to: nil)
            }
            return super.accessibilityActivationPoint
        }
        set { super.accessibilityActivationPoint = newValue }
    }
}
```

### Integration with State Changes

```swift
class StatefulCombinableView: UIView, AccessibilityCombinable {
    // Protocol requirements...
    var needsAccessibilityUpdate = false
    var rotorSequencer: AccessibilityComposition.RotorSequencer?
    var accessibilityInteractions: AccessibilityComposition.Interactions?
    var accessibilityCustomContent: [AXCustomContent]! = []
    
    // State that affects accessibility
    var isExpanded = false {
        didSet {
            if oldValue != isExpanded {
                needsAccessibilityUpdate = true
                // Announce state changes to assistive technology
                UIAccessibility.post(notification: .layoutChanged, argument: self)
            }
        }
    }
    
    var items: [String] = [] {
        didSet {
            needsAccessibilityUpdate = true
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Mark for update when layout changes (affects child positioning)
        needsAccessibilityUpdate = true
    }
    
    private func updateAccessibilityIfNeeded() {
        guard needsAccessibilityUpdate else { return }
        
        let combined = combineChildren()
        
        // Add state-specific information
        var modifiedRepresentation = combined
        modifiedRepresentation.value = isExpanded ? "Expanded, \(items.count) items" : "Collapsed"
        modifiedRepresentation.traits.insert(isExpanded ? .expanded : .notEnabled)
        
        applyAccessibility(modifiedRepresentation)
    }
}
```

### Best Practices for Custom Implementation

#### ✅ Do
- Always check `needsAccessibilityUpdate` before accessing any accessibility properties
- Set `needsAccessibilityUpdate = true` when content or state changes
- Override accessibility property getters to call `updateAccessibilityIfNeeded()`
- Implement all accessibility interaction methods that your view supports
- Use `UIAccessibility.post(notification:argument:)` for important state changes
- Test with VoiceOver to ensure the combined accessibility makes sense

#### ❌ Don't
- Forget to implement required protocol properties
- Skip the lazy update pattern (always updating is expensive)
- Override accessibility setters unless you have specific needs
- Ignore the `accessibilityInteractions` when implementing interaction methods

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
