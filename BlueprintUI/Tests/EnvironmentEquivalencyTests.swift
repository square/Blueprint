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
        var a = Environment()
        let b = a
        a[CountingKey.self] = 1
        #expect(CountingKey.comparisonCount == 0)
        #expect(!a.isEquivalent(to: b))
        // First comparison should call comparison method
        #expect(CountingKey.comparisonCount == 1)

        #expect(!a.isEquivalent(to: b))
        // Subsequent comparison should be cached
        #expect(CountingKey.comparisonCount == 1)

        #expect(!b.isEquivalent(to: a))
        // Reversed order should still be cached
        #expect(CountingKey.comparisonCount == 1)

        // Copying without mutation should preserve fingerprint, and be cached.
        let c = b
        #expect(CountingKey.comparisonCount == 1)
        #expect(!a.isEquivalent(to: c))
        #expect(CountingKey.comparisonCount == 1)

    }

    @Test func cascading() {

        // Note on ForcedResultKey:
        // Environment's equality checks iterate over the keys in its storage dictionary in a nondetermistic order, so we we just populate the dict with
        // a variety of keys, some true/false in different contexts. If we simply used CountingKey to observe comparisons, sometimes CountingKey woudln't be
        // compared, because the iteration would've already hit a false value earlier in the loop and bailed. Instead, we use ForcedResultKey to simulate this.

        var a = Environment()
        a[ForcedResultKey.self] = true
        var b = Environment()
        b[ForcedResultKey.self] = true

        var expectedCount = 0

        #expect(expectedCount == ForcedResultKey.comparisonCount)
        #expect(a.isEquivalent(to: b, in: .elementSizing))
        expectedCount += 1
        #expect(expectedCount == ForcedResultKey.comparisonCount)

        // A specific equivalency being true doesn't imply `.all` to be true, so we should see another evaluation.
        a[ForcedResultKey.self] = false
        #expect(!a.isEquivalent(to: b, in: .all))
        expectedCount += 1
        #expect(expectedCount == ForcedResultKey.comparisonCount)

        // `.all` equivalency implies that any more fine-grained equivalency should also be true, so we should be using a cached result.
        var c = Environment()
        c[ForcedResultKey.self] = true
        var d = Environment()
        d[ForcedResultKey.self] = true

        #expect(c.isEquivalent(to: d, in: .all))
        expectedCount += 1
        #expect(expectedCount == ForcedResultKey.comparisonCount)
        #expect(c.isEquivalent(to: d, in: .elementSizing))
        #expect(expectedCount == ForcedResultKey.comparisonCount)

        // A specific equivalency being false implies `.all` to be be false, so we should be using a cached result.
        var e = Environment()
        e[ForcedResultKey.self] = false
        let f = Environment()

        #expect(expectedCount == ForcedResultKey.comparisonCount)
        #expect(!e.isEquivalent(to: f, in: .elementSizing))
        expectedCount += 1
        #expect(expectedCount == ForcedResultKey.comparisonCount)
        #expect(!a.isEquivalent(to: b, in: .all))
        #expect(expectedCount == ForcedResultKey.comparisonCount)

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

    static func isEquivalent(lhs: Int, rhs: Int, in context: EquivalencyContext) -> Bool {
        alwaysEquivalentIn([.elementSizing], evaluatingContext: context)
    }
}

enum CountingKey: EnvironmentKey {
    static let defaultValue = 0
    static var comparisonCount = 0

    static func isEquivalent(lhs: Int, rhs: Int, in context: EquivalencyContext) -> Bool {
        comparisonCount += 1
        return lhs == rhs
    }
}

enum ForcedResultKey: EnvironmentKey {
    static let defaultValue: Bool? = nil
    static var comparisonCount = 0

    static func isEquivalent(lhs: Bool?, rhs: Bool?, in context: EquivalencyContext) -> Bool {
        comparisonCount += 1
        if let lhs {
            return lhs
        }
        return lhs == rhs
    }
}
