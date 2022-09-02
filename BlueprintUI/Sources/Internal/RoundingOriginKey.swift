import CoreGraphics

/// This key is used internally to cascade rounding information to nested BlueprintViews.
enum RoundingOriginKey: EnvironmentKey {
    static let defaultValue: CGPoint = .zero
}

extension Environment {
    var roundingOrigin: CGPoint {
        get { self[RoundingOriginKey.self] }
        set { self[RoundingOriginKey.self] = newValue }
    }
}
