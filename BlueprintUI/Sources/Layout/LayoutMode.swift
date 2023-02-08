import Foundation

public enum LayoutMode: Equatable {
    public static let `default`: Self = .strictSinglePass

    case standard
    case singlePass(options: SPCacheOptions = .default)
    case strictSinglePass
    
    public static let singlePass: Self = .singlePass()
}
