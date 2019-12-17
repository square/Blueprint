//
//  StringSizingCacheTests.swift
//  BlueprintUI-Unit-Tests
//
//  Created by Kyle Van Essen on 12/16/19.
//

import XCTest
@testable import BlueprintUI


class StringSizingCacheTests : XCTestCase
{
    func test_size()
    {
        
    }
    
    func test_performance()
    {
        let strings : [String] = [
            "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
            "Sed laoreet tristique nunc ac malesuada. Integer at tristique lacus. Ut tristique libero et libero vehicula, nec posuere libero tincidunt.",
            "Donec id suscipit elit, at sagittis sem. Duis faucibus tempus lacus et porta.",
            "Vivamus aliquam, nibh laoreet iaculis vehicula, sapien elit rhoncus leo, sed elementum augue risus vel orci. Vivamus imperdiet interdum quam vitae rutrum. Curabitur ac augue eu eros mollis pretium.",
            "Phasellus mauris velit, tristique id leo at, varius semper neque. Suspendisse potenti. Integer aliquet porta ante, et convallis est cursus ac.",
        ]
        
        let cachedTime = self.measureDuration {
            let cache = StringSizingCache()
            
            for string in strings {
                _ = cache.size(with: CGSize(width: 200.0, height: 1000.0), string: NSAttributedString(string: string), numberOfLines: 0)
            }
        }
        
        let uncachedTime = self.measureDuration {
            for string in strings {
                let attributed = NSAttributedString(string: string)
                
                _ = attributed.boundingRect(with: CGSize(width: 200.0, height: 1000.0), options: .usesLineFragmentOrigin, context: nil)
            }
        }
        
        print("Cached: \(cachedTime)")
        print("Uncached: \(uncachedTime)")
        
        XCTAssertTrue(cachedTime < uncachedTime)
    }
    
    private func measureDuration( _ block : () -> ()) -> TimeInterval
    {
        let start = Date()
        
        for _ in 1...10_000 {
            block()
        }
        
        return Date().timeIntervalSince(start)
    }
}
