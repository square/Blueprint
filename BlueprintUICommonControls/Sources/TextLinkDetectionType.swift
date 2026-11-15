import Foundation
import UIKit

/// Data that can be detected and exposed as interactive links in text.
public enum TextLinkDetectionType: Hashable {
    case date
    case address
    case link
    case phoneNumber

    var checkingType: NSTextCheckingResult.CheckingType {
        switch self {
        case .date: .date
        case .address: .address
        case .link: .link
        case .phoneNumber: .phoneNumber
        }
    }

    var dataDetectorType: UIDataDetectorTypes {
        switch self {
        case .date: .calendarEvent
        case .address: .address
        case .link: .link
        case .phoneNumber: .phoneNumber
        }
    }
}
