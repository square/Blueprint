//
//  SignpostLogger.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 5/8/20.
//

import os.signpost


/// Log types available within Listable.
extension OSLog {
    static let blueprintView = OSLog(
        subsystem: "com.square.BlueprintUI",
        category: "Blueprint View Update"
    )
}


/// An object which can be logged to `SignpostLogger`.
protocol SignpostLoggable {
    var signpostInfo : SignpostLoggingInfo { get }
}


/// The info logged to `SignpostLogger` from a `SignpostLoggable`.
struct SignpostLoggingInfo {
    var identifiers : [String]
}


///
/// Signpost logging is logging visible in Instruments.app
///
/// Blueprint utilizes signpost logging to instrument various parts of the
/// update cycle: Measuring, laying out, creating and updating UIViews, etc.
///
/// Resources
/// ---------
///  WWDC 2018: https://developer.apple.com/videos/play/wwdc2018/405/
///  WWDC 2019: https://developer.apple.com/wwdc20/10168
///  Swift By Sundell: https://www.swiftbysundell.com/wwdc2018/getting-started-with-signposts/
///
struct SignpostLogger {
    
    #if DEBUG
    /// You may temporarily set this param to `false` to disable os_signpost logging,
    /// for example if debugging performance in Instruments.app.
    ///
    /// Note that tests will fail while this is set to `false` in `DEBUG`, to ensure
    /// this is not accidentally committed as `false`.
    static let isLoggingEnabled = true
    #else
    static let isLoggingEnabled = false
    #endif
    
    static func log<Output>(log : OSLog, name: StaticString, for loggable : SignpostLoggable? = nil, _ output : () -> Output) -> Output
    {
        guard self.isLoggingEnabled else {
            return output()
        }
        
        self.log(.begin, log: log, name: name, for: loggable)
        
        let output = output()
        
        self.log(.end, log: log, name: name, for: loggable)
        
        return output
    }
    
    static func log(_ type : EventType, log : OSLog, name: StaticString, for loggable : SignpostLoggable? = nil)
    {
        guard self.isLoggingEnabled else {
            return
        }
        
        if #available(iOS 12.0, *) {
            if let loggable = loggable {
                os_signpost(
                    type.toSignpostType,
                    log: log,
                    name: name,
                    "%{public}s",
                    Self.debuggingIdentifier(for: loggable)
                )
            } else {
                os_signpost(
                    type.toSignpostType,
                    log: log,
                    name: name
                )
            }
        }
    }
    
    enum EventType {
        case begin
        case event
        case end
        
        @available(iOS 12.0, *)
        var toSignpostType : OSSignpostType {
            switch self {
            case .begin: return .begin
            case .event: return .event
            case .end: return .end
            }
        }
    }
    
    private static func debuggingIdentifier(for loggable : SignpostLoggable) -> String {
        
        let info = loggable.signpostInfo
        
        return info.identifiers.joined(separator: " ")
    }
}
