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

    func test_convenience() throws {
        let enabled = Box().userInteractionEnabled()
        XCTAssertTrue(try view(from: enabled).isUserInteractionEnabled)

        let disabled = Box().userInteractionEnabled(false)
        XCTAssertFalse(try view(from: disabled).isUserInteractionEnabled)
    }

    // MARK: - helpers -
    func view(from element: UserInteractionEnabled) throws -> UIView {
        let description = try XCTUnwrap(element.backingViewDescription(
            with: .init(
                bounds: .zero,
                subtreeExtent: nil,
                environment: .empty
            )
        ))
        let view = UIView()
        view.isUserInteractionEnabled = !element.isEnabled
        description.apply(to: view)
        return view
    }
}
