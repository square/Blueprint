//
//  InteractiveElementTests.swift
//
//
//  Created by Kyle Van Essen on 12/5/22.
//

import BlueprintUI
import BlueprintUICommonControls
import UIKit
import XCTest



struct ButtonElement: InteractiveViewElement {

    var viewContent: Content {
        InteractiveViewElementContent { state in
            Box(backgroundColor: .red)
                .constrainedTo(size: .init(width: 100, height: 100))
        } view: { _, _ in
            View.describe { _ in }
        }
    }

    struct State: InteractiveViewElementContentState {

        var isEnabled: Bool
        var isPressed: Bool

        static var defaultValue: State {
            .init(
                isEnabled: false,
                isPressed: false
            )
        }
    }
}


extension ButtonElement {

    final class View: UIControl {

        let content: BlueprintView

        override init(frame: CGRect) {

            content = BlueprintView()

            super.init(frame: frame)

            content.frame = bounds
            addSubview(content)
        }

        required init?(coder: NSCoder) {
            fatalError()
        }

        override func layoutSubviews() {
            super.layoutSubviews()

            content.frame = bounds
        }


    }
}

class InteractiveElementTests: XCTestCase {

    func test_element() {}
}
