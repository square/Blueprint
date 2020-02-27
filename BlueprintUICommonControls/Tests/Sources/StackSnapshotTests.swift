//
//  StackSnapshotTests.swift
//  BlueprintUICommonControls-Unit-Tests
//
//  Created by Kyle Van Essen on 2/25/20.
//

import Foundation
import XCTest

import BlueprintUICommonControls
import BlueprintUI

class StackSnapshotTests : XCTestCase {
    
    func test_snapshot()
    {
        compareSnapshot(of: TestElement(), size: CGSize(width: 300.0, height: 200.0), identifier: "truncated")
    }
}

fileprivate struct TestElement: ProxyElement {
    var elementRepresentation: Element {
        return Column { column in
            column.verticalUnderflow = .justifyToCenter
            column.horizontalAlignment = .fill

            column.add(child: row(withMargin: 0))
            column.add(child: row(withMargin: 50))
        }
    }

    func row(withMargin margin: CGFloat) -> Element {
        return Row { row in
            row.horizontalOverflow = .condenseProportionally

            row.add(
                growPriority: 0,
                shrinkPriority: 0,
                child: Spacer(size: CGSize(width: margin, height: 0)))

            row.add(
                growPriority: 1,
                shrinkPriority: 1,
                child: Label(text: "This is a long label for testing. It takes up 2 lines if there are no margins, but needs 3 if we add some margins."))

            row.add(
                growPriority: 0,
                shrinkPriority: 0,
                child: Spacer(size: CGSize(width: margin, height: 0)))
        }
    }
}

