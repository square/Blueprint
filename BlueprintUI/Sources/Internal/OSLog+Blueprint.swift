import Foundation
import os.log

extension OSLog {
    /// When logging is enabled, `active` is set to this log.
    static let blueprint = OSLog(subsystem: "com.squareup.Blueprint", category: "Blueprint")

    /// The log to be used for `os_log` and `os_signpost` logging.
    static var active: OSLog = OSLog.disabled
}

/// Namespace for logging config.
public enum BlueprintLogging {
    /// If enabled, Blueprint will emit signpost logs. You can view these logs in Instruments to
    /// aid in debugging or performance tuning.
    ///
    /// Signpost logging is disabled by default.
    public static var enabled: Bool {
        get {
            OSLog.active === OSLog.blueprint
        }
        set {
            OSLog.active = newValue ? .blueprint : .disabled
        }
    }
}
