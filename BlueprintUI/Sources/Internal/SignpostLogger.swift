//
//  SignpostLogger.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 5/8/20.
//

import os.signpost



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
public struct SignpostLogger {
    
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
    
    static func log<Output>(name: StaticString, info : Info? = nil, _ output : () -> Output) -> Output
    {
        guard self.isLoggingEnabled else {
            return output()
        }
        
        self.log(.begin, name: name, info: info)
        
        let output = output()
        
        self.log(.end, name: name, info: info)
        
        return output
    }
    
    static func log(_ type : EventType, name: StaticString, info: Info? = nil)
    {
        guard self.isLoggingEnabled else {
            return
        }
        
        if #available(iOS 12.0, *) {
            if let info = info {
                os_signpost(
                    type.toSignpostType,
                    log: .blueprint,
                    name: name,
                    "%{public}s",
                    info.stringValue
                )
            } else {
                os_signpost(
                    type.toSignpostType,
                    log: .blueprint,
                    name: name
                )
            }
        }
    }
    
    /// The info logged to `SignpostLogger` from a `SignpostLoggable`.
    public struct Info {
        
        private var typeString : () -> String
        private var components : () -> [String]
        
        public init(
            type valueType : @escaping @autoclosure () -> Any,
            components: @escaping @autoclosure () -> [String] = [String]()
        ) {
            self.typeString = { String(describing: valueType()) }
            self.components = components
        }
        
        var stringValue : String {

            var string = ""
            
            string += self.typeString()
            
            let components = self.components()
            
            if components.isEmpty == false {
                string += ": "
                string += components.joined(separator: ", ")
            }
            
            return string
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
}


fileprivate extension OSLog {
    static let blueprint = OSLog(
        subsystem: "com.square.BlueprintUI",
        category: "BlueprintUI"
    )
}
