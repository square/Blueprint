@testable import BlueprintUI
import Foundation
import XCTest

final class RenderContextTests: XCTestCase {
    func test_mode() {
        let view = BlueprintView()
        XCTAssertNil(view.layoutMode)
        
        // If the default ever changes we'll need to update this test
        XCTAssertEqual(LayoutMode.default, .standard)

        var contextualMode: LayoutMode?

        view.element = EnvironmentReader { _ in

            // this element measurement is "out-of-band", meaning the enclosing render doesn't
            // know about it and can't explicitly pass it any info
            _ = EnvironmentReader { _ in
                contextualMode = RenderContext.current?.layoutMode
                return Empty()
            }
            .content
            .measure(in: .unconstrained, environment: .empty)
            
            return Empty()
        }
        
        view.ensureLayoutPass()
        XCTAssertEqual(contextualMode, .default)
        
        view.layoutMode = .singlePass
        view.ensureLayoutPass()
        XCTAssertEqual(contextualMode, .singlePass)
    }
}
