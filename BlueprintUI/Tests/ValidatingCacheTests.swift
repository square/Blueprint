import Foundation
import Testing
@_spi(HostingViewContext) @testable import BlueprintUI

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

@MainActor
struct EnvironmentValidatingCacheTests {

    @Test func basic() {
        var cache = EnvironmentValidatingCache<String, String>()
        var environment = Environment()
        environment[ExampleKey.self] = 1
        let one = cache.retrieveOrCreate(key: "Hello", environment: environment, context: .all) {
            _ = $0[ExampleKey.self]
            return "One"
        }
        #expect(one == "One")

        let two = cache.retrieveOrCreate(key: "Hello", environment: environment, context: .all) {
            _ = $0[ExampleKey.self]
            return "Two"
        }
        #expect(two == "One")

        let three = cache.retrieveOrCreate(key: "KeyMiss", environment: environment, context: .all) {
            _ = $0[ExampleKey.self]
            return "Three"
        }
        #expect(three == "Three")

        var differentEnvironment = environment
        differentEnvironment[ExampleKey.self] = 2
        let four = cache.retrieveOrCreate(key: "Hello", environment: differentEnvironment, context: .all) {
            _ = $0[ExampleKey.self]
            return "Four"
        }
        #expect(four == "Four")
    }

}


@MainActor
struct EnvironmentAndValueValidatingCacheTests {

    @Test func basic() {
        var cache = EnvironmentAndValueValidatingCache<String, String, String>()
        var environment = Environment()
        environment[ExampleKey.self] = 1
        let one = cache.retrieveOrCreate(
            key: "Hello",
            environment: environment,
            validationValue: "Validate",
            context: .all
        ) {
            _ = $0[ExampleKey.self]
            return "One"
        }
        #expect(one == "One")

        let two = cache.retrieveOrCreate(
            key: "Hello",
            environment: environment,
            validationValue: "Validate",
            context: .all
        ) {
            _ = $0[ExampleKey.self]
            return "Two"
        }
        #expect(two == "One")

        let three = cache.retrieveOrCreate(
            key: "KeyMiss",
            environment: environment,
            validationValue: "Validate",
            context: .all
        ) {
            _ = $0[ExampleKey.self]
            return "Three"
        }
        #expect(three == "Three")

        var differentEnvironment = environment
        differentEnvironment[ExampleKey.self] = 2
        let four = cache.retrieveOrCreate(
            key: "Hello",
            environment: differentEnvironment,
            validationValue: "Validate",
            context: .all
        ) {
            _ = $0[ExampleKey.self]
            return "Four"
        }
        #expect(four == "Four")

        let five = cache.retrieveOrCreate(
            key: "Hello",
            environment: differentEnvironment,
            validationValue: "Invalid",
            context: .all
        ) { _ in
            "Five"
        }
        #expect(five == "Five")
    }

    @Test func basicElementsAndPaths() {

        var cache = EnvironmentAndValueValidatingCache<String, CGSize, TestCachedElement>()
        let elementOne = TestCachedElement(value: "Hello")
        let elementOnePath = "some/element/path"
        let elementTwo = TestCachedElement(value: "Hi")
        let elementTwoPath = "some/other/path"
        let elementOneModified = TestCachedElement(value: "Hello World")
        var environment = Environment()

        var evaluationCount = 0
        func sizeForElement(element: TestCachedElement) -> CGSize {
            evaluationCount += 1
            // Fake size obviously, for demo purposes
            return CGSize(width: element.value.count * 10, height: 100)
        }

        // First will be a key miss, so evaluate.
        let firstSize = cache.retrieveOrCreate(
            key: elementOnePath,
            environment: environment,
            validationValue: elementOne,
            context: .elementSizing
        ) { _ in
            sizeForElement(element: elementOne)
        }
        #expect(firstSize == CGSize(width: 50, height: 100))
        #expect(evaluationCount == 1)

        // Second will be a key miss also, so evaluate.
        let secondSize = cache.retrieveOrCreate(
            key: elementTwoPath,
            environment: environment,
            validationValue: elementTwo,
            context: .elementSizing
        ) { _ in
            sizeForElement(element: elementTwo)
        }
        #expect(secondSize == CGSize(width: 20, height: 100))
        #expect(evaluationCount == 2)

        // Querying first size again with matching environment and validation value. Cache hit, validation pass, no evaluation.
        let firstSizeAgain = cache.retrieveOrCreate(
            key: elementOnePath,
            environment: environment,
            validationValue: elementOne,
            context: .elementSizing
        ) { _ in
            sizeForElement(element: elementOne)
        }
        #expect(firstSizeAgain == CGSize(width: 50, height: 100))
        #expect(evaluationCount == 2)

        // Querying first size again with matching environment and non-matching validation value. Cache hit, validation fail, evaluation.
        let firstSizeWithNewElement = cache.retrieveOrCreate(
            key: elementOnePath,
            environment: environment,
            validationValue: elementOneModified,
            context: .elementSizing
        ) { _ in
            sizeForElement(element: elementOneModified)
        }
        #expect(firstSizeWithNewElement == CGSize(width: 110, height: 100))
        #expect(evaluationCount == 3)

        // Querying first size again with matching environment and validation value. Cache hit, validation pass, no evaluation.
        let firstSizeWithNewElementAgain = cache.retrieveOrCreate(
            key: elementOnePath,
            environment: environment,
            validationValue: elementOneModified,
            context: .elementSizing
        ) { _ in
            sizeForElement(element: elementOneModified)
        }
        #expect(firstSizeWithNewElementAgain == CGSize(width: 110, height: 100))
        #expect(evaluationCount == 3)

        // Querying first size again with matching environment and original validation value. Cache hit, validation fail (because we don't preserve old values for keys with different validations), evaluation.
        let originalFirstSizeAgain = cache.retrieveOrCreate(
            key: elementOnePath,
            environment: environment,
            validationValue: elementOne,
            context: .elementSizing
        ) { _ in
            sizeForElement(element: elementOne)
        }
        #expect(originalFirstSizeAgain == CGSize(width: 50, height: 100))
        #expect(evaluationCount == 4)

        // Querying first size again with non-equivalent environment and matching validation value. Cache hit, validation fail (due to environment diff), evaluation.
        environment[ExampleKey.self] = 1
        let firstSizeWithNewEnvironment = cache.retrieveOrCreate(
            key: elementOnePath,
            environment: environment,
            validationValue: elementOneModified,
            context: .elementSizing
        ) { _ in
            sizeForElement(element: elementOne)
        }
        #expect(firstSizeWithNewEnvironment == CGSize(width: 50, height: 100))
        #expect(evaluationCount == 5)


    }

}

struct TestCachedElement: Element, Equatable, ContextuallyEquivalent {
    let value: String

    var content: ElementContent {
        fatalError()
    }

    func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        fatalError()
    }

}
