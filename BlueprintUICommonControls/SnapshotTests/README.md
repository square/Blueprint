# Accessibility Snapshot Testing with Custom Filenames

This directory contains accessibility snapshot tests for BlueprintUI components with automatic filename generation.

## Custom Filename Format

The `assertAccessibilitySnapshot` wrapper automatically generates filenames in the format:
```
{test_name}_{ios_version}_{screen_size}@{screen_scale}x.png
```

### Examples

- `test_label_accessibility_snapshot_18.0_393x852@3x.png`
- `test_button_accessibility_snapshot_18.0_393x852@3x.png`
- `test_complex_layout_17.5_414x896@2x.png`

## Usage

### Basic Usage
```swift
func test_my_component() {
    let view = createMyComponent()
    assertAccessibilitySnapshot(of: view)
}
```

### With Custom Name
```swift
func test_my_component_special_case() {
    let view = createMyComponent()
    assertAccessibilitySnapshot(of: view, named: "custom_name")
}
```

### With Different Snapshot Strategy
```swift
func test_my_component_image() {
    let view = createMyComponent()
    assertAccessibilitySnapshot(of: view, as: .image)
}
```

## Benefits

1. **Consistent Naming**: All snapshot files follow the same naming convention
2. **Device Awareness**: Filenames include device-specific information (screen size, scale)
3. **iOS Version Tracking**: Helps identify when snapshots need updating for new iOS versions
4. **Easy Debugging**: Clear filenames make it easy to identify which test and device configuration failed

## Files

- `XCTestCase+AccessibilitySnapshot.swift`: Contains the reusable extension
- `AccessibilitySnapshotTests.swift`: Example usage and test cases

## Implementation Details

The wrapper:
1. Extracts device information (screen size, scale, iOS version)
2. Cleans up the test name (removes parentheses)
3. Formats the information into a consistent filename
4. Passes through all other parameters to the original `assertSnapshot` function

This ensures compatibility with all existing `assertSnapshot` features while providing automatic filename generation.
