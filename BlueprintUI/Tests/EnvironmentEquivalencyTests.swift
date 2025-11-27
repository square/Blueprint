import Testing
@testable import BlueprintUI

@MainActor
struct EnvironmentEquivalencyTests {

    @Test func simpleEquivalency() {
        let a = Environment()
        let b = Environment()
        #expect(a.isEquivalent(to: b, in: .all))
        #expect(a.isEquivalent(to: b, in: .elementSizing))
    }

    @Test func simpleChange() {
        var a = Environment()
        a[ExampleKey.self] = 1
        let b = Environment()
        #expect(!a.isEquivalent(to: b, in: .all))
        #expect(!a.isEquivalent(to: b, in: .elementSizing))
    }

    @Test func orderingWithDefaults() {
        // The ordering of the comparison shouldn't matter if one value has a setting but the other doesn't.
        var a = Environment()
        a[ExampleKey.self] = 1
        let b = Environment()
        #expect(!a.isEquivalent(to: b))

        // Explicitly duplicated to ensure we don't hit a cached comparison.
        let c = Environment()
        var d = Environment()
        d[ExampleKey.self] = 1
        #expect(!c.isEquivalent(to: d))
    }

    @Test func orderingWithNullability() {
        // The ordering of the comparison shouldn't matter if one value has a setting but the other doesn't.
        var a = Environment()
        a[OptionalKey.self] = 1
        let b = Environment()
        #expect(!a.isEquivalent(to: b))

        // Explicitly duplicated to ensure we don't hit a cached comparison.
        let c = Environment()
        var d = Environment()
        d[OptionalKey.self] = 1
        #expect(!c.isEquivalent(to: d))
    }

    @Test func modification() {
        var a = Environment()
        let b = a
        a[ExampleKey.self] = 1
        #expect(!a.isEquivalent(to: b))
    }

    @Test func caching() {
        BlueprintLogging.isEnabled = true
        var hookedResult: [String] = []
        Logger.hook = {
            hookedResult.append($0)
        }
        var a = Environment()
        let b = a
        a[ExampleKey.self] = 1
        hookedResult = []
        #expect(!a.isEquivalent(to: b))
        #expect(hookedResult.contains("logEnvironmentEquivalencyFingerprintCacheMiss(environment:) \(a.fingerprint)"))

        hookedResult = []
        #expect(!a.isEquivalent(to: b))
        // Subsequent comparison should be cached
        #expect(hookedResult.contains("logEnvironmentEquivalencyFingerprintCacheHit(environment:) \(a.fingerprint)"))

        hookedResult = []
        #expect(!b.isEquivalent(to: a))
        // Reversed order should still be cached
        #expect(hookedResult.contains("logEnvironmentEquivalencyFingerprintCacheHit(environment:) \(b.fingerprint)"))

        hookedResult = []
        let c = b
        #expect(!a.isEquivalent(to: c))
        // Copying without mutation should preserve fingerprint, and be cached.
        #expect(hookedResult.contains("logEnvironmentEquivalencyFingerprintCacheHit(environment:) \(a.fingerprint)"))

    }

    @Test func cascading() {
        BlueprintLogging.isEnabled = true
        var hookedResult: [String] = []
        Logger.hook = {
            hookedResult.append($0)
        }
        var a = Environment()
        a[ExampleKey.self] = 1
        a[NonSizeAffectingKey.self] = 1
        var b = Environment()
        b[ExampleKey.self] = 1
        b[NonSizeAffectingKey.self] = 2

        hookedResult = []
        #expect(a.isEquivalent(to: b, in: .elementSizing))
        #expect(hookedResult.contains("logEnvironmentEquivalencyFingerprintCacheMiss(environment:) \(a.fingerprint)"))

        hookedResult = []
        #expect(!a.isEquivalent(to: b, in: .all))
        // A specific equivalency being true doesn't imply `.all` to be true, so we should see another evaluation.
        #expect(hookedResult.contains("logEnvironmentEquivalencyFingerprintCacheMiss(environment:) \(a.fingerprint)"))

        var c = Environment()
        c[ExampleKey.self] = 1
        var d = Environment()
        d[ExampleKey.self] = 1

        hookedResult = []
        #expect(c.isEquivalent(to: d, in: .all))
        #expect(hookedResult.contains("logEnvironmentEquivalencyFingerprintCacheMiss(environment:) \(c.fingerprint)"))

        hookedResult = []
        #expect(c.isEquivalent(to: d, in: .elementSizing))
        // `.all` equivalency implies that any more fine-grained equivalency should also be true, so we should be using a cached result.
        #expect(hookedResult.contains("logEnvironmentEquivalencyFingerprintCacheHit(environment:) \(c.fingerprint)"))

        // A specific equivalency being false implies `.all` to be be false, so we should be using a cached result.
        var e = Environment()
        e[ExampleKey.self] = 2
        let f = Environment()

        hookedResult = []
        #expect(!e.isEquivalent(to: f, in: .elementSizing))
        #expect(hookedResult.contains("logEnvironmentEquivalencyFingerprintCacheMiss(environment:) \(e.fingerprint)"))

        hookedResult = []
        #expect(!e.isEquivalent(to: f, in: .all))
        #expect(hookedResult.contains("logEnvironmentEquivalencyFingerprintCacheHit(environment:) \(e.fingerprint)"))

    }

    func hello(closure: @autoclosure () -> Bool, message: String) {
        var hookedResult: [String] = []
        Logger.hook = {
            hookedResult.append($0)
        }
        #expect(closure())
        #expect(hookedResult.contains(message))
    }

}

enum ExampleKey: EnvironmentKey {
    static let defaultValue = 0
}

enum OptionalKey: EnvironmentKey {
    static let defaultValue: Int? = nil
}

enum NonSizeAffectingKey: EnvironmentKey {
    static let defaultValue = 0

    static func isEquivalent(lhs: Int, rhs: Int, in context: CrossLayoutCacheableContext) -> Bool {
        alwaysEquivalentIn([.elementSizing], evaluatingContext: context)
    }
}
