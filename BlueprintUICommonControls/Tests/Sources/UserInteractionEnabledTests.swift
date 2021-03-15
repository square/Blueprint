//
//  UserInteractionEnabledTests.swift
//  BlueprintUICommonControls-Unit-Tests
//
//  Created by Noah Blake on 3/15/20.
//

import XCTest
import BlueprintUI
import BlueprintUICommonControls

final class UserInteractionEnabledTests: XCTestCase {
    func test() throws {
        func makeView(enabled: Bool) throws -> UIView {
            let wrapped = UserInteractionEnabled(enabled, wrapping: Box())
            let description = try XCTUnwrap(wrapped.backingViewDescription(bounds: .zero, subtreeExtent: nil))
            let view = UIView()
            view.isUserInteractionEnabled = !enabled
            description.apply(to: view)
            return view
        }

        XCTAssertTrue(try makeView(enabled: true).isUserInteractionEnabled)
        XCTAssertFalse(try makeView(enabled: false).isUserInteractionEnabled)
    }
}
