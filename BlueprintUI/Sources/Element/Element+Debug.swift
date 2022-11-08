import Foundation


extension Element {

    @_spi(Debugging)
    public func debugScope(_ scope: String) -> Element {
        adaptedEnvironment { environment in
            environment[DebugScopeKey.self].append(scope)
        }
    }
}


enum DebugScopeKey: EnvironmentKey {

    static let defaultValue: [String] = []
}
