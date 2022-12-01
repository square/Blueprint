import Foundation

public enum LayoutMode: Equatable {
    public static let `default`: Self = .strictSinglePass

    case standard
    case singlePass
    case strictSinglePass
}
