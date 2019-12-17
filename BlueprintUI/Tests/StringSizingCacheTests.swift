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
            
            """
            Cras ultricies aliquam nisl, dictum maximus massa semper vitae. Maecenas mattis tempus turpis. Integer fermentum purus in velit posuere, vitae tristique lorem eleifend. Duis ultricies mauris massa, a auctor nibh ultrices quis. Sed ultricies auctor facilisis. Vivamus a lacus accumsan, pellentesque justo vulputate, molestie tortor. Mauris ut nunc quis lacus sagittis faucibus. Praesent sed posuere tortor, facilisis commodo erat. Quisque arcu lorem, egestas at luctus sit amet, dictum ut lacus. Phasellus ac sapien in massa mollis dapibus. Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Nullam ultricies tortor ut lobortis luctus.

            Maecenas viverra justo lectus, quis consectetur augue rhoncus ut. In porta tellus eu pellentesque cursus. Donec ultrices tortor tellus, vel elementum urna aliquet sit amet. Morbi metus arcu, lobortis in lacus egestas, tincidunt condimentum turpis. Nam sit amet dui velit. Nullam lacinia mauris pharetra est porta, ac sodales nulla pellentesque. Pellentesque feugiat venenatis libero id placerat.
            """,
            
            """
            Cras ut enim sed nibh tempor sollicitudin lobortis sed lacus. Praesent eget luctus arcu. Integer eget est blandit, rutrum quam sit amet, hendrerit risus. Vestibulum cursus efficitur turpis, quis varius mauris semper at. Integer tempor eu nulla ut lacinia. Sed a orci volutpat, volutpat magna id, porta leo. Vestibulum posuere purus orci, at sollicitudin tortor consectetur sed.

            Sed ut nisl a nunc tempus bibendum. Integer semper lorem sed augue feugiat ullamcorper. Sed at sapien eget enim rhoncus viverra nec a sem. Ut commodo tellus mauris, a finibus tortor mattis vel. Mauris sed justo vestibulum, molestie tortor ut, ullamcorper turpis. Proin a varius neque. Curabitur leo orci, porttitor ut enim ut, blandit commodo magna. Fusce hendrerit cursus dui, non faucibus arcu hendrerit eget. Integer vitae faucibus nunc. Praesent auctor eros quis auctor feugiat. Proin nibh urna, consequat at suscipit quis, aliquet id urna. Suspendisse commodo, est id vulputate iaculis, nulla arcu accumsan tortor, eget sagittis arcu libero at turpis.
            """,
        ]
        
        let cache = StringSizingCache()
        
        let cachedTime = self.measureDuration {
            
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
