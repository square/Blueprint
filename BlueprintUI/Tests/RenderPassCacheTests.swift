import XCTest
@testable import BlueprintUI

final class RenderPassCacheTests: XCTestCase {
    func test_caching() {
        let cache = RenderPassCache(name: "test", signpostRef: self, screenScale: 1)

        XCTAssertEqual(cache.name, "test")
        XCTAssert(cache.signpostRef === self)
        XCTAssertNil(cache[SizeConstraint.unconstrained])

        cache[SizeConstraint.unconstrained] = CGSize(width: 1, height: 1)
        cache[SizeConstraint(CGSize(width: 2, height: 2))] = CGSize(width: 2, height: 2)
        cache[SizeConstraint(height: 3)] = CGSize(width: 3, height: 3)
        cache[SizeConstraint(width: 4)] = CGSize(width: 4, height: 4)

        XCTAssertEqual(
            cache[SizeConstraint.unconstrained],
            CGSize(width: 1, height: 1)
        )
        XCTAssertEqual(
            cache[SizeConstraint(CGSize(width: 2, height: 2))],
            CGSize(width: 2, height: 2)
        )
        XCTAssertEqual(
            cache[SizeConstraint(height: 3)],
            CGSize(width: 3, height: 3)
        )
        XCTAssertEqual(
            cache[SizeConstraint(width: 4)],
            CGSize(width: 4, height: 4)
        )
        XCTAssertNil(cache[SizeConstraint(CGSize(width: 9, height: 9))])
    }

    func test_subcaches() {
        let cache = RenderPassCache(name: "test", signpostRef: self, screenScale: 1)

        let subcache1 = cache.subcache(key: 0, name: "1")
        let subcache2 = cache.subcache(key: 1, name: "2")

        XCTAssertEqual(subcache1.name, "1")
        XCTAssert(subcache1.signpostRef === self)

        XCTAssertEqual(subcache2.name, "2")
        XCTAssert(subcache2.signpostRef === self)

        let size1 = CGSize(width: 1, height: 1)
        let size2 = CGSize(width: 2, height: 2)
        let size3 = CGSize(width: 3, height: 3)

        cache[SizeConstraint(size1)] = size1
        subcache1[SizeConstraint(size2)] = size2
        subcache2[SizeConstraint(size3)] = size3

        XCTAssertEqual(cache[SizeConstraint(size1)], size1)
        XCTAssertNil(subcache1[SizeConstraint(size1)])
        XCTAssertNil(subcache2[SizeConstraint(size1)])

        XCTAssertEqual(subcache1[SizeConstraint(size2)], size2)
        XCTAssertNil(cache[SizeConstraint(size2)])
        XCTAssertNil(subcache2[SizeConstraint(size2)])

        XCTAssertEqual(subcache2[SizeConstraint(size3)], size3)
        XCTAssertNil(subcache1[SizeConstraint(size3)])
        XCTAssertNil(cache[SizeConstraint(size3)])
    }

    /// Test the get(_: orStore:) convenience method
    func test_getOrStore() {
        let cache = RenderPassCache(name: "test", signpostRef: self, screenScale: 1)

        let size1 = CGSize(width: 1, height: 1)

        var measureCount = 0

        var val = cache.get(SizeConstraint(size1)) { constraint -> CGSize in
            XCTAssertEqual(constraint, SizeConstraint(size1))
            measureCount += 1
            return size1
        }
        XCTAssertEqual(val, size1)

        val = cache.get(SizeConstraint(size1)) { constraint -> CGSize in
            XCTAssertEqual(constraint, SizeConstraint(size1))
            measureCount += 1
            return size1
        }
        XCTAssertEqual(val, size1)

        XCTAssertEqual(measureCount, 1)
    }

    /// Test the convenience methods for subcaches
    func test_elementSubcaches() {
        func unusedName() -> String {
            XCTFail("Cache name should only be evaluated on creation")
            return "unused"
        }

        do {
            let cache = RenderPassCache(name: "test", signpostRef: self, screenScale: 1)

            let singletonSubcache = cache.subcache(element: Empty())
            XCTAssertEqual(singletonSubcache.name, "test.Empty")
            XCTAssert(cache.subcache(key: 0, name: unusedName()) === singletonSubcache)
        }

        do {
            let cache = RenderPassCache(name: "test", signpostRef: self, screenScale: 1)

            let singletonSubcache = cache.subcache(index: 0, of: 1, element: Empty())
            XCTAssertEqual(singletonSubcache.name, "test.Empty")
            XCTAssert(cache.subcache(key: 0, name: unusedName()) === singletonSubcache)
        }

        do {
            let cache = RenderPassCache(name: "test", signpostRef: self, screenScale: 1)

            let subcache1 = cache.subcache(index: 0, of: 2, element: Empty())
            let subcache2 = cache.subcache(index: 1, of: 2, element: Empty())

            XCTAssertEqual(subcache1.name, "test[0].Empty")
            XCTAssertEqual(subcache2.name, "test[1].Empty")

            XCTAssert(cache.subcache(key: 0, name: unusedName()) === subcache1)
            XCTAssert(cache.subcache(key: 1, name: unusedName()) === subcache2)
        }
    }
}
