import Foundation
import os.log

extension OSLog {
    /// When logging is enabled, `active` is set to this log.
    static let blueprint = OSLog(subsystem: "com.squareup.Blueprint", category: "Blueprint")

    /// The log to be used for `os_log` and `os_signpost` logging.
    fileprivate(set) static var active: OSLog = OSLog.disabled
}

/// Namespace for logging config.
public enum BlueprintLogging {

    /// Configuration for logging options
    public struct Config {

        /// When `true`, timing data will be logged when measuring each `Element`
        public var recordElementMeasures: Bool

        public init(recordElementMeasures: Bool) {
            self.recordElementMeasures = recordElementMeasures
        }
    }

    /// Logging configuration
    public static var config: Config = .lite

    /// If enabled, Blueprint will emit signpost logs. You can view these logs in Instruments to
    /// aid in debugging or performance tuning.
    ///
    /// Signpost logging is disabled by default.
    public static var isEnabled: Bool {
        get {
            OSLog.active === OSLog.blueprint
        }
        set {
            OSLog.active = newValue ? .blueprint : .disabled
        }
    }
}

extension BlueprintLogging.Config {
    /// Logging configuration that will not record measurement data for all `Element`s.
    /// This provides a reasonable balance between data collection and performance impact.
    /// This is the default logging configuration.
    public static let lite = Self(recordElementMeasures: false)

    /// Logging configuration that includes measurement data.
    /// This provides the most granular information, but has a noticeable impact on performance.
    public static let verbose = Self(recordElementMeasures: true)
}
