import Foundation

extension Environment {
    private enum CalendarKey: EnvironmentKey {
        static var defaultValue: Calendar {
            Calendar.current
        }
    }

    /// The current calendar that elements should use when handling dates.
    ///
    /// Defaults to `Calendar.current`.
    public var calendar: Calendar {
        get { self[CalendarKey.self] }
        set { self[CalendarKey.self] = newValue }
    }
}
