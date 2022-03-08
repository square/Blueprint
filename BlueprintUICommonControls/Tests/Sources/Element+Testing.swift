//
//  File.swift
//
//
//  Created by Kyle Van Essen on 1/12/22.
//

import BlueprintUI
import UIKit
import XCTest


extension Element {

    /// Provides the backing view to the access closure.
    func accessBackingView(in view: BlueprintView, _ access: (UIView) throws -> Void) rethrows {

        XCTAssertNotNil(
            backingViewDescription(
                with: .init(bounds: view.bounds, subtreeExtent: nil, environment: view.environment)
            ),
            "Must provide a view-backed element to `accessBackingView`."
        )

        view.element = centered()
        view.layoutIfNeeded()

        defer {
            view.element = nil
            view.layoutIfNeeded()
        }

        let elementView = view.subviews[0].subviews[0]

        try access(elementView)
    }
}
