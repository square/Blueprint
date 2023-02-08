import CoreGraphics
import Foundation


final class SPCacheTree<Key, Value, SubcacheKey> where Key: Hashable, SubcacheKey: Hashable {
    
    typealias Subcache = SPCacheTree<Key, Value, SubcacheKey>
    
    private var valueCache: SPValueCache<Key, Value>
    private var subcaches: [SubcacheKey: Subcache] = [:]
    
    var path: String
    
    private var layoutSubviews: [LayoutSubview]?
    
    private var _associatedCache: Any?
    
    init(path: String, options: SPCacheOptions) {
        self.path = path
        valueCache = .init(path: path, options: options)
    }
    
    func subcache(key: SubcacheKey) -> Subcache {
        if let subcache = subcaches[key] {
            return subcache
        }
        let subcache = Subcache(path: "\(path)/\(key)", options: valueCache.options)
        subcaches[key] = subcache
        return subcache
    }
    
    func layoutSubviews(create: () -> [LayoutSubview]) -> [LayoutSubview] {
        if let layoutSubviews = layoutSubviews {
            return layoutSubviews
        }
        let layoutSubviews = create()
        self.layoutSubviews = layoutSubviews
        return layoutSubviews
    }
    
    // TODO: Generalize using a EnvironmentKey system for better type safety?
    func associatedCache<AssociatedCache>(create: () -> AssociatedCache) -> AssociatedCache {
        if let associatedCache = _associatedCache as? AssociatedCache {
            return associatedCache
        }
        
        let associatedCache = create()
        _associatedCache = associatedCache
        return associatedCache
    }

    func `set`<AssociatedCache>(associatedCache: AssociatedCache) {
        _associatedCache = associatedCache
    }

}

extension SPCacheTree where Key == SizeConstraint, Value == CGSize {
    func get(key: Key, or create: (Key) -> Value) -> Value {
        valueCache.get(key: key, or: create)
    }
}

final class SPValueCache<Key: Hashable, Value> {
    
    typealias Options = SPCacheOptions

    var values: [Key: Value] = [:]
    
    var path: String
    var options: Options
    
    init(path: String, options: Options) {
        self.path = path
        self.options = options
    }
}

public struct SPCacheOptions: Equatable {
    
    public static let `default` = SPCacheOptions(
        hintRangeBoundaries: true,
        searchUnconstrainedKeys: true
    )

    public var hintRangeBoundaries: Bool
    public var searchUnconstrainedKeys: Bool

    public init(hintRangeBoundaries: Bool, searchUnconstrainedKeys: Bool) {
        self.hintRangeBoundaries = hintRangeBoundaries
        self.searchUnconstrainedKeys = searchUnconstrainedKeys
    }
}

extension SPValueCache where Key == SizeConstraint, Value == CGSize {

    func get(key: Key, or create: (Key) -> Value) -> Value {
        if let size = values[key] {
            Logger.logCacheHit(object: self, description: path, constraint: key)
            return size
        }
        
        // TODO:
        // This has a negative perf impact on deep stack tests. Need to determine what the impact
        // is on a wider variety of tests, and if there is a way we can avoid this for cases
        // where it doesn't help (e.g. not in a scroll view).
        if options.searchUnconstrainedKeys {
            if
                case .atMost(let maxHeight) = key.height,
                let size = values[.init(width: key.width, height: .unconstrained)],
                size.height <= maxHeight
            {
                Logger.logCacheUnconstrainedSearchMatch(
                    object: self,
                    description: path,
                    constraint: key,
                    match: .init(width: key.width, height: .unconstrained)
                )
                values[key] = size
                return size
            }
            
            if
                case .atMost(let maxWidth) = key.width,
                let size = values[.init(width: .unconstrained, height: key.height)],
                size.width <= maxWidth
            {
                Logger.logCacheUnconstrainedSearchMatch(
                    object: self,
                    description: path,
                    constraint: key,
                    match: .init(width: .unconstrained, height: key.height)
                )
                // TODO: test with and without caching this
                values[key] = size
                return size
            }
            
            if
                case .atMost(let maxWidth) = key.width,
                case .atMost(let maxHeight) = key.height,
                let size = values[.unconstrained],
                size.width <= maxWidth,
                size.height <= maxHeight
            {
                Logger.logCacheUnconstrainedSearchMatch(
                    object: self,
                    description: path,
                    constraint: key,
                    match: .unconstrained
                )
                values[key] = size
                return size
            }
        }
        
        Logger.logCacheMiss(object: self, description: path, constraint: key)
        
        Logger.logMeasureStart(object: self, description: path, constraint: key)
        let size = create(key)
        Logger.logMeasureEnd(object: self)

        values[key] = size
        
        if options.hintRangeBoundaries {
            switch (key.width, key.height) {
            case (.unconstrained, .unconstrained):
                values[SizeConstraint(width: .unconstrained, height: .atMost(size.height))] = size
                values[SizeConstraint(width: .atMost(size.width), height: .unconstrained)] = size
                values[SizeConstraint(size)] = size
                
            case (.unconstrained, .atMost(let maxHeight)):
                if size.height < maxHeight {
                    values[SizeConstraint(width: .unconstrained, height: .atMost(size.height))] = size
                    values[SizeConstraint(size)] = size
                }
                values[SizeConstraint(width: .atMost(size.width), height: key.height)] = size
                
            case (.atMost(let maxWidth), .unconstrained):
                if size.width < maxWidth {
                    values[SizeConstraint(width: .atMost(size.width), height: .unconstrained)] = size
                    values[SizeConstraint(size)] = size
                }
                values[SizeConstraint(width: key.width, height: .atMost(size.height))] = size
                
            case (.atMost(let maxWidth), .atMost(let maxHeight)):
                if size.width < maxWidth {
                    values[SizeConstraint(width: .atMost(size.width), height: key.height)] = size
                }
                if size.height < maxHeight {
                    values[SizeConstraint(width: key.width, height: .atMost(size.height))] = size
                }
                if size.height < maxWidth && size.width < maxWidth {
                    values[SizeConstraint(size)] = size
                }
            }
        }
        
        return size
    }
}


typealias SPCacheNode = SPCacheTree<SizeConstraint, CGSize, ElementIdentifier>
