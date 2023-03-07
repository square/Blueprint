import Foundation

/// Controls the layout system that Blueprint uses to lay out elements.
///
/// Blueprint supports multiple layout systems. Each is expected to produce the same result, but
/// some may have different performance profiles or special requirements.
///
/// You can change the layout system used by setting the ``BlueprintView/layoutMode`` property, but
/// generally you should use the ``default`` option.
///
public enum LayoutMode: Equatable {
    public static let `default`: Self = .legacy

    /// The "standard" layout system.
    case legacy

    /// A newer layout system with some optimizations made possible by ensuring elements adhere
    /// certain contract for behavior.
    case caffeinated
}
