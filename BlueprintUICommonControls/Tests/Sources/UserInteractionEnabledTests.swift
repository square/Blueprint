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
        let enabled = UserInteractionEnabled(true, wrapping: Box())
        XCTAssertTrue(try view(from: enabled).isUserInteractionEnabled)

        let disabled = UserInteractionEnabled(false, wrapping: Box())
        XCTAssertFalse(try view(from: disabled).isUserInteractionEnabled)
    }

    func test_disabled() throws {
        let enabled = Box().disabled(false)
        XCTAssertTrue(try view(from: enabled).isUserInteractionEnabled)

        let disabled = Box().disabled()
        XCTAssertFalse(try view(from: disabled).isUserInteractionEnabled)
    }

    func test_enabled() throws {
        let enabled = Box().enabled()
        XCTAssertTrue(try view(from: enabled).isUserInteractionEnabled)

        let disabled =  Box().enabled(false)
        XCTAssertFalse(try view(from: disabled).isUserInteractionEnabled)
    }

    // MARK: - helpers -
    func view(from element: UserInteractionEnabled) throws -> UIView {
        let description = try XCTUnwrap(element.backingViewDescription(bounds: .zero, subtreeExtent: nil))
        let view = UIView()
        view.isUserInteractionEnabled = !element.isEnabled
        description.apply(to: view)
        return view
    }
}
