import Foundation

extension Environment {
    private enum TimeZoneKey: EnvironmentKey {
        static var defaultValue: TimeZone {
            TimeZone.current
        }
    }

    /// The current time zone that elements should use when handling dates.
    ///
    /// Defaults to `TimeZone.current`.
    public var timeZone: TimeZone {
        get { self[TimeZoneKey.self] }
        set { self[TimeZoneKey.self] = newValue }
    }
}
