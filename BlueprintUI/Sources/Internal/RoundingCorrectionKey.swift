import CoreGraphics

/// This key is used internally to cascade rounding information to nested BlueprintViews.
enum RoundingCorrectionKey: EnvironmentKey {
    static let defaultValue: CGRect = .zero
}

extension Environment {
    var roundingCorrection: CGRect {
        get { self[RoundingCorrectionKey.self] }
        set { self[RoundingCorrectionKey.self] = newValue }
    }
}
