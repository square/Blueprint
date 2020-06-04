import UIKit

extension Environment {
    private enum DisplayScaleKey: EnvironmentKey {
        static var defaultValue: CGFloat {
            UIScreen.main.scale
        }
    }

    /// The display scale of this environment.
    ///
    /// This value is the number of pixels per point. A value of 1.0 indicates non-Retina screens,
    /// 2.0 indicates 2x Retina screens, etc.
    public var displayScale: CGFloat {
        get { self[DisplayScaleKey.self] }
        set { self[DisplayScaleKey.self] = newValue }
    }
}
