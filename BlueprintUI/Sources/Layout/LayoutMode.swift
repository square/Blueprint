import Foundation

/// Controls the layout system that Blueprint uses to lay out elements.
///
/// Blueprint supports multiple layout systems. Each is expected to produce the same result, but
/// some may have different performance profiles or special requirements.
///
/// You can change the layout system used by setting the ``BlueprintView/layoutMode`` property, but
/// generally you should use the ``default`` option.
///
/// Changing the default will cause all instances of ``BlueprintView`` to be invalidated, and re-
/// render their contents.
///
public struct LayoutMode: Hashable {
    public static var `default`: Self = .caffeinated {
        didSet {
            guard oldValue != .default else { return }
            NotificationCenter
                .default
                .post(name: .defaultLayoutModeChanged, object: nil)
        }
    }

    /// A newer layout system with some optimizations made possible by ensuring elements adhere
    /// to a certain contract for behavior.
    public static func caffeinated(options: LayoutOptions = .default) -> Self {
        LayoutMode(options: options)
    }

    /// A newer layout system with some optimizations made possible by ensuring elements adhere
    /// to a certain contract for behavior.
    public static let caffeinated = Self.caffeinated()

    /// The name of the layout mode.
    public var name: String {
        "Caffeinated"
    }

    public var options: LayoutOptions
}

extension LayoutMode: CustomStringConvertible {
    public var description: String {
        switch (options.hintRangeBoundaries, options.searchUnconstrainedKeys) {
        case (true, true):
            return "Caffeinated (hint+search)"
        case (true, false):
            return "Caffeinated (hint)"
        case (false, true):
            return "Caffeinated (search)"
        case (false, false):
            return "Caffeinated"
        }
    }
}

extension Notification.Name {
    static let defaultLayoutModeChanged: Self = .init(
        "com.squareup.blueprint.defaultLayoutModeChanged"
    )
}
