import Foundation

public enum LayoutMode: Equatable {
    public static let `default`: Self = .strictSinglePass

    case standard
    case singlePass
    case strictSinglePass
}

enum LayoutModeDependent<StandardPayload, SinglePassPayload, StrictPayload> {
    case standard(StandardPayload)
    case singlePass(SinglePassPayload)
    case strict(StrictPayload)
    
    init(
        mode: LayoutMode,
        standard: @autoclosure () -> StandardPayload,
        singlePass: @autoclosure () -> SinglePassPayload,
        strict: @autoclosure () -> StrictPayload
    ) {
        switch mode {
        case .standard:
            self = .standard(standard())
        case .singlePass:
            self = .singlePass(singlePass())
        case .strictSinglePass:
            self = .strict(strict())
        }
    }
}

typealias LayoutModeDependentCache = LayoutModeDependent<CacheTree, SPCacheNode, StrictCacheNode>

extension LayoutModeDependentCache {
    func outOfBandCache(for key: AnyHashable) -> Self {
        switch self {
        case .standard(let cache):
            return .standard(cache.outOfBandCache(key: key))
            
        case .singlePass(let cache):
            return .singlePass(cache.outOfBandCache(for: key))
            
        case .strict(let cache):
            return .strict(cache.outOfBandCache(for: key))
        }
    }
}
