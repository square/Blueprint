import Foundation

extension Optional where Wrapped: RangeReplaceableCollection {

    public static func + (left: Wrapped?, right: Wrapped?) -> Wrapped? {
        let val = (left ?? Wrapped()) + (right ?? Wrapped())
        return val.isEmpty ? nil : val
    }

}
