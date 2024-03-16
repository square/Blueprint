import CoreGraphics

/// A measurement cache that automatically "hints" values that can be deduced from the Caffeinated
/// Layout contract.
///
/// See the documentation for more details about the layout contract and hinting optimizations.
///
final class HintingSizeCache {

    typealias Options = LayoutOptions
    typealias Key = SizeConstraint
    typealias Value = CGSize

    private var values: [Key: Value] = [:]
    private var hasUnconstrainedWidth: Bool = false
    private var hasUnconstrainedHeight: Bool = false

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

        // This option allows us to deduce if the key is within a hinted range even if it does not
        // land on a boundary value, by searching "well known" keys.
        if options.searchUnconstrainedKeys {

            // When there are no unconstrained keys, searching for them here can have a significant
            // performance hit. Unconstrained keys are usually not present unless introduced by an
            // element like a ScrollView.
            //
            // To avoid this hit, we track whether we have a seen an unconstrained key in either
            // axis, and check that before attempting a search.

            defer {
                // We only need to track the explicit lookup key. The hinted keys from
                // deduced range boundaries will never introduce a new unconstrained key.

                hasUnconstrainedWidth = hasUnconstrainedWidth || key.width == .unconstrained
                hasUnconstrainedHeight = hasUnconstrainedHeight || key.height == .unconstrained
            }

            if
                hasUnconstrainedHeight,
                case .atMost = key.width,
                case .atMost(let maxHeight) = key.height,
                let size = values[.init(width: key.width, height: .unconstrained)],
                size.height <= maxHeight
            {
                Logger.logCacheUnconstrainedSearchMatch(
                    object: signpostRef,
                    description: path,
                    constraint: key,
                    match: .init(width: key.width, height: .unconstrained)
                )
                values[key] = size
                return size
            }

            if
                hasUnconstrainedWidth,
                case .atMost = key.height,
                case .atMost(let maxWidth) = key.width,
                let size = values[.init(width: .unconstrained, height: key.height)],
                size.width <= maxWidth
            {
                Logger.logCacheUnconstrainedSearchMatch(
                    object: signpostRef,
                    description: path,
                    constraint: key,
                    match: .init(width: .unconstrained, height: key.height)
                )
                values[key] = size
                return size
            }
        }

        // This particular log has a small, but non-negligible impact on a certain class of test
        // cases, such as deeply nested stacks. Enable it manually if you want this statistic.
        // Logger.logCacheMiss(object: signpostRef, description: path, constraint: key)

        Logger.logMeasureStart(object: signpostRef, description: path, constraint: key)
        let size = create(key)
        Logger.logMeasureEnd(object: signpostRef)

        values[key] = size

        // This option adds (or "hints") extra cache keys along the boundaries of the range
        // between the constraint and the measured size.
        if options.hintRangeBoundaries {

            func hint(key: SizeConstraint) {
                values[key] = size
            }

            switch (key.width, key.height) {
            case (.unconstrained, .unconstrained):
                hint(key: SizeConstraint(width: .unconstrained, height: .atMost(size.height)))
                hint(key: SizeConstraint(width: .atMost(size.width), height: .unconstrained))
                hint(key: SizeConstraint(size))

            case (.unconstrained, .atMost(let maxHeight)):
                if size.height < maxHeight {
                    hint(key: SizeConstraint(width: .unconstrained, height: .atMost(size.height)))
                    hint(key: SizeConstraint(size))
                }
                hint(key: SizeConstraint(width: .atMost(size.width), height: key.height))

            case (.atMost(let maxWidth), .unconstrained):
                if size.width < maxWidth {
                    hint(key: SizeConstraint(width: .atMost(size.width), height: .unconstrained))
                    hint(key: SizeConstraint(size))
                }
                hint(key: SizeConstraint(width: key.width, height: .atMost(size.height)))

            case (.atMost(let maxWidth), .atMost(let maxHeight)):
                if size.width < maxWidth {
                    hint(key: SizeConstraint(width: .atMost(size.width), height: key.height))
                }
                if size.height < maxHeight {
                    hint(key: SizeConstraint(width: key.width, height: .atMost(size.height)))
                }
                if size.width < maxWidth && size.height < maxHeight {
                    hint(key: SizeConstraint(size))
                }
            }
        }

        return size
    }
}
