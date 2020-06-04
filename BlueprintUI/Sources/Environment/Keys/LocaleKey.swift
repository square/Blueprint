import Foundation

extension Environment {
    private enum LocaleKey: EnvironmentKey {
        static var defaultValue: Locale {
            Locale.current
        }
    }

    /// The current locale that elements should use.
    ///
    /// Defaults to `Locale.current`.
    public var locale: Locale {
        get { self[LocaleKey.self] }
        set { self[LocaleKey.self] = newValue }
    }
}

