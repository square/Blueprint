import Foundation

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

    static func detectLinks(in text: NSAttributedString, types: Set<Self>) -> [(url: URL, range: NSRange)] {
        guard !types.isEmpty else {
            return []
        }

        let checkingTypes = NSTextCheckingResult.CheckingType(types)

        guard let detector = try? NSDataDetector(types: checkingTypes.rawValue) else {
            return []
        }

        var links: [(url: URL, range: NSRange)] = []

        detector.enumerateMatches(
            in: text.string,
            options: [],
            range: NSRange(location: 0, length: text.length)
        ) { result, _, _ in
            guard let result = result else {
                return
            }

            switch result.resultType {
            case .phoneNumber:
                if let phoneNumber = result.phoneNumber {
                    let charactersToRemove = CharacterSet.decimalDigits.inverted
                    let trimmedPhoneNumber = phoneNumber.components(separatedBy: charactersToRemove).joined()
                    if let url = URL(string: "tel:\(trimmedPhoneNumber)") {
                        links.append((url, result.range))
                    }
                }

            case .link:
                if let url = result.url {
                    links.append((url, result.range))
                }

            case .address:
                if let addressComponents = result.addressComponents {
                    let components = [
                        addressComponents[.name],
                        addressComponents[.organization],
                        addressComponents[.street],
                        addressComponents[.city],
                        addressComponents[.zip],
                        addressComponents[.country],
                    ]

                    let address = components
                        .compactMap { $0 }
                        .joined(separator: " ")

                    if let urlQuery = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                       let url = URL(string: "https://maps.apple.com/?address=\(urlQuery)")
                    {
                        links.append((url, result.range))
                    }
                }

            case .date:
                if let date = result.date,
                   let url = URL(string: "calshow:\(date.timeIntervalSinceReferenceDate)")
                {
                    links.append((url, result.range))
                }

            default:
                break
            }
        }

        return links
    }
}

extension NSTextCheckingResult.CheckingType {
    init(_ types: Set<TextLinkDetectionType>) {
        var checkingType = NSTextCheckingResult.CheckingType()

        for type in types {
            checkingType.formUnion(type.checkingType)
        }

        self = checkingType
    }
}
