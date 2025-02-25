import UIKit

extension UIAccessibilityTraits {

    /// `UIAccessibilityTraits` contains a private trait that is used for back buttons
    /// in `UINavigationController`, on `_UIButtonBarButton`.
    /// We will use this same private trait to mirror the expected standard back button experience.
    ///
    /// ```
    /// (lldb) po button
    /// ▿ Optional<UIControl>
    ///   - some : <_UIButtonBarButton: 0x1026336d0 ... >
    ///
    /// (lldb) p button?.accessibilityTraits
    /// (UIAccessibilityTraits?) 134217728
    ///
    /// (lldb) po String(134217728, radix: 2)
    /// "1000000000000000000000000000"
    ///
    /// (lldb) po String(134217728, radix: 2).count - 1
    /// 27
    /// ```
    package static let backButton: UIAccessibilityTraits = UIAccessibilityTraits(rawValue: 1 << 27)


    /// `UIAccessibilityTraits` contains a trait that is used on `UISwitch`
    /// prior to iOS 17 this trait was private but was later exposed as `.toggleButton`.
    /// We will reference the trait by its raw value but provide an alternative name to avoid conflicting with the public trait .
    ///
    package static let _toggleButton = UIAccessibilityTraits(rawValue: 1 << 53)
}
