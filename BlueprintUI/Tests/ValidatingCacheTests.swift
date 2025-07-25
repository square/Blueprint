import Testing
@_spi(CacheStorage) @testable import BlueprintUI

@MainActor
struct ValidatingCacheTests {

    @Test func setAndRetrieve() {
        var cache = ValidatingCache<String, String, Void>()
        var createCount = 0
        var validateCount = 0
        let value = cache.retrieveOrCreate(key: "Hello") {
            fatalError()
        } create: {
            createCount += 1
            return ("World", ())
        }
        #expect(value == "World")
        #expect(createCount == 1)
        #expect(validateCount == 0)
        let secondValue = cache.retrieveOrCreate(key: "Hello") {
            validateCount += 1
            return true
        } create: {
            createCount += 1
            return ("Hello", ())
        }
        #expect(secondValue == "World")
        #expect(createCount == 1)
        #expect(validateCount == 1)
    }

    @Test func invalidation() {
        var cache = ValidatingCache<String, String, Void>()
        var createCount = 0
        var validateCount = 0

        let value = cache.retrieveOrCreate(key: "Hello") { _ in
            validateCount += 1
            return true
        } create: {
            createCount += 1
            return ("One", ())
        }
        #expect(value == "One")
        #expect(createCount == 1)
        #expect(validateCount == 0)
        let secondValue = cache.retrieveOrCreate(key: "Hello") { _ in
            validateCount += 1
            return true
        } create: {
            createCount += 1
            return ("Two", ())
        }
        #expect(secondValue == "One")
        #expect(createCount == 1)
        #expect(validateCount == 1)

        let thirdValue = cache.retrieveOrCreate(key: "Hello") {
            validateCount += 1
            return false
        } create: {
            createCount += 1
            return ("Three", ())
        }
        #expect(thirdValue == "Three")
        #expect(createCount == 2)
        #expect(validateCount == 2)
    }

}

struct EnvironmentValidatingCacheTests {

    @Test func basic() {
        var cache = EnvironmentValidatingCache<String, String>()
        var environment = Environment()
        environment[ExampleKey.self] = 1
        let one = cache.retrieveOrCreate(key: "Hello", environment: environment, context: .all) {
            "One"
        }
        #expect(one == "One")

        let two = cache.retrieveOrCreate(key: "Hello", environment: environment, context: .all) {
            "Two"
        }
        #expect(two == "One")

        let three = cache.retrieveOrCreate(key: "KeyMiss", environment: environment, context: .all) {
            "Three"
        }
        #expect(three == "Three")

        var differentEnvironment = environment
        differentEnvironment[ExampleKey.self] = 2
        let four = cache.retrieveOrCreate(key: "Hello", environment: differentEnvironment, context: .all) {
            "Four"
        }
        #expect(four == "Four")
    }

}
