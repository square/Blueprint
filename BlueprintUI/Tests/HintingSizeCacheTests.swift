import XCTest
@testable import BlueprintUI

final class HintingSizeCacheTests: XCTestCase {

    func test_caching() {

        func test(key: SizeConstraint) {
            let size = CGSize(width: 100, height: 100)

            let boundaries = key.boundaries(betweenSelfAndSize: size)
            // test all the keys twice
            let keys = boundaries + boundaries

            assertMisses(
                keys: keys,
                size: size,
                // we expect to hit each of the unique keys exactly once
                misses: boundaries,
                options: .init(
                    hintRangeBoundaries: false,
                    searchUnconstrainedKeys: false,
                    measureableStorageCache: false
                )
            )
        }

        test(key: SizeConstraint(width: .atMost(200), height: .atMost(200)))
        test(key: SizeConstraint(width: .atMost(200), height: .unconstrained))
        test(key: SizeConstraint(width: .unconstrained, height: .atMost(200)))
        test(key: .unconstrained)
    }

    func test_hintRangeBoundaries() throws {

        func test(key: SizeConstraint) {
            let size = CGSize(width: 100, height: 100)

            let boundaries = key.boundaries(betweenSelfAndSize: size)
            let offKeys = [
                SizeConstraint(width: key.width, height: .atMost(150)),
                SizeConstraint(width: .atMost(150), height: key.height),
            ]
            // test all the keys twice
            let keys = boundaries + boundaries + offKeys + offKeys

            assertMisses(
                keys: keys,
                size: size,
                // we expect to miss the first key, deduce the other boundaries, and miss the off keys
                misses: [key] + offKeys,
                options: .init(hintRangeBoundaries: true, searchUnconstrainedKeys: false, measureableStorageCache: false)
            )
        }

        test(key: SizeConstraint(width: .atMost(200), height: .atMost(200)))
        test(key: SizeConstraint(width: .atMost(200), height: .unconstrained))
        test(key: SizeConstraint(width: .unconstrained, height: .atMost(200)))
        test(key: .unconstrained)
    }

    func test_searchUnconstrainedKeys() {

        let size = CGSize(width: 100, height: 100)

        assertMisses(
            keys: [
                SizeConstraint(width: .atMost(200), height: .unconstrained),
                SizeConstraint(width: .atMost(200), height: .atMost(200)),
            ],
            size: size,
            // we expect to hit only the first key, and range-match the second
            misses: [SizeConstraint(width: .atMost(200), height: .unconstrained)],
            options: .init(hintRangeBoundaries: false, searchUnconstrainedKeys: true, measureableStorageCache: false)
        )

        assertMisses(
            keys: [
                SizeConstraint(width: .unconstrained, height: .atMost(200)),
                SizeConstraint(width: .atMost(200), height: .atMost(200)),
            ],
            size: size,
            // we expect to hit only the first key, and range-match the second
            misses: [SizeConstraint(width: .unconstrained, height: .atMost(200))],
            options: .init(hintRangeBoundaries: false, searchUnconstrainedKeys: true, measureableStorageCache: false)
        )

        let keys = [
            .unconstrained,
            SizeConstraint(width: .atMost(200), height: .atMost(200)),
            SizeConstraint(width: .unconstrained, height: .atMost(200)),
            SizeConstraint(width: .atMost(200), height: .unconstrained),
        ]
        assertMisses(
            keys: keys,
            size: size,
            // we do not search the double-unconstrained key, so these are all misses
            misses: keys,
            options: .init(hintRangeBoundaries: false, searchUnconstrainedKeys: true, measureableStorageCache: false)
        )
    }

    func test_hintRangeBoundariesAndSearchUnconstrained() {
        let size = CGSize(width: 100, height: 100)

        assertMisses(
            keys: [
                .unconstrained,
                SizeConstraint(width: .atMost(100), height: .atMost(150)),
                SizeConstraint(width: .atMost(150), height: .atMost(100)),
            ],
            size: size,
            // we will miss the first key, but can then range-match the others off of hinted boundary keys
            misses: [.unconstrained],
            options: .init(hintRangeBoundaries: true, searchUnconstrainedKeys: true, measureableStorageCache: false)
        )
    }

    /// Assert that a `HintingSizeCache` misses on the expected keys.
    ///
    /// - Parameters:
    ///   - keys: Keys to probe the cache with, in order. The expected misses are probably always a subset of these.
    ///   - size: A fixed size that the measuring function should return to the cache.
    ///   - expectedMisses: The keys that are expected to generate a cache miss and call the measurer.
    ///   - options: Options for the cache under test.
    private func assertMisses(
        keys: [SizeConstraint],
        size: CGSize,
        misses expectedMisses: [SizeConstraint],
        options: LayoutOptions,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let cache = HintingSizeCache(
            path: "test",
            signpostRef: SignpostToken(),
            options: options
        )

        var misses: [SizeConstraint] = []

        func measure(_ constraint: SizeConstraint) -> CGSize {
            misses.append(constraint)
            return size
        }

        for key in keys {
            XCTAssertEqual(
                cache.get(key: key, or: measure),
                size,
                file: file,
                line: line
            )
        }

        XCTAssertEqual(misses, expectedMisses, file: file, line: line)
    }
}

extension SizeConstraint {
    /// Generate constraints with every permutation of width & height between `self` and the given size.
    func boundaries(betweenSelfAndSize size: CGSize) -> [SizeConstraint] {
        [
            self,
            .init(width: width, height: .atMost(size.height)),
            .init(width: .atMost(size.width), height: height),
            .init(size),
        ]
    }
}
