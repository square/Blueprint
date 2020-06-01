import XCTest
@testable import BlueprintUI

class ViewDescriptionTests: XCTestCase {

    func test_build() {
        let description = TestView.describe { config in
            config.builder = { TestView(initializationProperty: "hello") }
        }

        let view = description.build() as! TestView

        XCTAssertEqual(view.initializationProperty, "hello")
    }

    func test_apply() {
        let description = TestView.describe { config in
            config.apply {
                $0.mutableProperty = "testing"
            }
        }

        let view = description.build() as! TestView
        description.apply(to: view)
        XCTAssertEqual(view.mutableProperty, "testing")

        let secondDescription = TestView.describe { config in
            config.apply { $0.mutableProperty = "123" }
        }
        secondDescription.apply(to: view)
        XCTAssertEqual(view.mutableProperty, "123")
    }

    func test_bind() {
        let description = TestView.describe { config in
            config[\.mutableProperty] = "testing"
        }

        let view = description.build() as! TestView
        description.apply(to: view)
        XCTAssertEqual(view.mutableProperty, "testing")

        let secondDescription = TestView.describe { config in
            config[\.mutableProperty] = "123"
        }
        secondDescription.apply(to: view)
        XCTAssertEqual(view.mutableProperty, "123")
    }

}


private final class TestView: UIView {

    let initializationProperty: String

    var mutableProperty: String = ""

    init(initializationProperty: String) {
        self.initializationProperty = initializationProperty
        super.init(frame: .zero)
    }

    override init(frame: CGRect) {
        self.initializationProperty = ""
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
