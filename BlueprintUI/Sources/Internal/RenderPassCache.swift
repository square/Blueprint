import CoreGraphics

/// A cache implementation suitable for the lifetime of a single render pass or measurement.
final class RenderPassCache: CacheTree {

    let name: String
    let signpostRef: AnyObject

    private var subcaches: [SubcacheKey: RenderPassCache] = [:]
    private var measurements: [SizeConstraint: CGSize] = [:]

    init(name: String, signpostRef: AnyObject) {
        self.name = name
        self.signpostRef = signpostRef
    }

    subscript(constraint: SizeConstraint) -> CGSize? {
        get {
            measurements[constraint]
        }
        set {
            measurements[constraint] = newValue
        }
    }

    func subcache(key: SubcacheKey, name: @autoclosure () -> String) -> CacheTree {
        if let subcache = subcaches[key] {
            return subcache
        }

        let subcache = RenderPassCache(name: name(), signpostRef: signpostRef)
        subcaches[key] = subcache
        return subcache
    }
    
    var debugDescription: String {
        var value = ""
        self.buildDebugDescription(in: &value, depth: 0)
        return value
    }
    
    private func buildDebugDescription(in string : inout String, depth : Int) {
        
        func measurementsString() -> String {
            self.measurements.map { constraint, measurement in
                return "(\(constraint.width) x \(constraint.height)) -> (\(measurement.width), \(measurement.height))"
            }
            .joined(separator: "\n")
        }
        
        let node =
            """
            name: "\(self.name)"
            measurement count: \(self.measurements.count)
            measurements: \n\(measurementsString().inset(by: 1))
            """
            .inset(by: depth)
        
        string.append("\n")
        string.append(node)
        
        if self.subcaches.isEmpty == false {
            string.append("\n")
            string.append(
                """
                -----
                Children:
                """
                .inset(by: depth)
            )
            
            for sub in self.subcaches.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
                sub.value.buildDebugDescription(in: &string, depth: depth + 1)
            }
        }
    }
}

fileprivate extension String {
    func inset(by depth : Int) -> String {
        self.split(separator: "\n")
            .map { Array(repeating: " ", count: depth * 3) + $0 }
            .joined(separator: "\n")
    }
}
