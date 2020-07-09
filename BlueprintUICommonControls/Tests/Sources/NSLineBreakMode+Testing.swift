import UIKit

extension NSLineBreakMode: CustomStringConvertible {
    static let all: [NSLineBreakMode] = [
        .byCharWrapping,
        .byClipping,
        .byTruncatingHead,
        .byTruncatingMiddle,
        .byTruncatingTail,
        .byWordWrapping
    ]

    public var description: String {
        switch self {
        case .byCharWrapping:
            return "byCharWrapping"
        case .byClipping:
            return "byClipping"
        case .byTruncatingHead:
            return "byTruncatingHead"
        case .byTruncatingMiddle:
            return "byTruncatingMiddle"
        case .byTruncatingTail:
            return "byTruncatingTail"
        case .byWordWrapping:
            return "byWordWrapping"
        @unknown default:
            return "unknown"
        }
    }
}

