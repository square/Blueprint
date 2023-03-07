import CoreGraphics

/// A measurement cache that automatically "hints" values that can be deduced from the Caffeinated
/// Layout contract.
final class HintingSizeCache {

    typealias Options = LayoutOptions
    typealias Key = SizeConstraint
    typealias Value = CGSize

    private var values: [Key: Value] = [:]

    let path: String
    let signpostRef: AnyObject
    let options: Options

    init(path: String, signpostRef: AnyObject, options: Options) {
        self.path = path
        self.signpostRef = signpostRef
        self.options = options
    }

    func get(key: Key, or create: (Key) -> Value) -> Value {
        if let size = values[key] {
            Logger.logCacheHit(object: signpostRef, description: path, constraint: key)
            return size
        }

        // TODO: implement hinting

        // This particular log has a small, but non-negligible impact on a certain class of test
        // cases, such as deeply nested stacks. Enable it manually if you want this statistic.
        // Logger.logCacheMiss(object: signpostRef, description: path, constraint: key)

        Logger.logMeasureStart(object: signpostRef, description: path, constraint: key)
        let size = create(key)
        Logger.logMeasureEnd(object: signpostRef)

        values[key] = size

        return size
    }
}
