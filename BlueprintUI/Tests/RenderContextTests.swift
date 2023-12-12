import Foundation
import XCTest
@testable import BlueprintUI

final class RenderContextTests: XCTestCase {
    // TODO: Decide what to do here. Can't test overrides w/ only one layout mode...
//    func test_mode() {
//        let view = BlueprintView()
//        XCTAssertNil(view.layoutMode)
//
//        let defaultMode: LayoutMode = .default
//        let overrideMode: LayoutMode = defaultMode == .legacy
//            ? .caffeinated
//            : .legacy
//
//        var contextualMode: LayoutMode?
//
//        view.element = EnvironmentReader { _ in
//
//            // this element measurement is "out-of-band", meaning the enclosing render doesn't
//            // know about it and can't explicitly pass it any info
//            _ = EnvironmentReader { _ in
//                contextualMode = RenderContext.current?.layoutMode
//                return Empty()
//            }
//            .content
//            .measure(in: .unconstrained, environment: .empty)
//
//            return Empty()
//        }
//
//        view.ensureLayoutPass()
//        XCTAssertEqual(contextualMode, defaultMode)
//
//        view.layoutMode = overrideMode
//        view.ensureLayoutPass()
//        XCTAssertEqual(contextualMode, overrideMode)
//    }
}
