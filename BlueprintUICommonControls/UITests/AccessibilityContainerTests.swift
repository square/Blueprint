import BlueprintUI
import UIKit
import XCTest
@testable import BlueprintUICommonControls

class AccessibilityContainerTests: XCTestCase {

    func test_accessibilityElementsWithCollectionView() {
        let rootVC = UIViewController()

        // Root container
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 400, height: 1000))
        rootVC.view = root

        // Accessible views
        let v1 = MockAccessibleView(label: "Top Left", frame: CGRect(x: 10, y: 14, width: 50, height: 50))
        let v2 = MockAccessibleView(label: "Top Right", frame: CGRect(x: 300, y: 10, width: 50, height: 50))
        let v3 = MockAccessibleView(label: "Middle", frame: CGRect(x: 150, y: 19, width: 50, height: 50))

        // Non-accessible view
        let nonAX = UIView(frame: CGRect(x: 0, y: 100, width: 50, height: 50))
        nonAX.isAccessibilityElement = false

        // Hidden view
        let hidden = MockAccessibleView(label: "Hidden", frame: CGRect(x: 0, y: 150, width: 50, height: 50))
        hidden.isHidden = true

        // accessibilityElementsHidden view
        let axHiddenContainer = UIView(frame: CGRect(x: 0, y: 300, width: 100, height: 50))
        axHiddenContainer.accessibilityElementsHidden = true
        let childOfAXHidden = MockAccessibleView(label: "Child", frame: CGRect(x: 10, y: 0, width: 50, height: 50))
        axHiddenContainer.addSubview(childOfAXHidden)

        // Nested accessible subview inside non-accessible container
        let container = UIView(frame: CGRect(x: 0, y: 400, width: 100, height: 50))
        let nested = MockAccessibleView(label: "Nested", frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        container.addSubview(nested)

        // Collection view
        let collectionView = MockCollectionView(cellCount: 5)
        collectionView.frame = CGRect(x: 0, y: 500, width: 300, height: 200)
        collectionView.layoutIfNeeded()

        // Add all to root
        [v1, v2, v3, nonAX, hidden, axHiddenContainer, container, collectionView].forEach {
            root.addSubview($0)
        }

        show(vc: rootVC) { _ in
            let elements = root.recursiveAccessibilityElements()
            let labels = elements.compactMap {
                ($0 as? UIView)?.accessibilityLabel
                    ?? ($0 as? UIAccessibilityElement)?.accessibilityLabel
            }

            XCTAssertEqual(labels, ["Top Left", "Top Right", "Middle", "Nested"])
            XCTAssertFalse(labels.contains("Hidden"))
            XCTAssertFalse(labels.contains("Child")) // from axHiddenContainer

            // Should include the UICollectionView itself, not its cells
            XCTAssertTrue(elements.contains { $0 as? UICollectionView === collectionView })

            // Expected count: 4 accessible views + 1 collection view
            XCTAssertEqual(elements.count, 5)
        }
    }
}

extension AccessibilityContainerTests {
    class MockCell: UICollectionViewCell {
        let label = UILabel()

        override init(frame: CGRect) {
            super.init(frame: frame)
            label.isAccessibilityElement = true
            label.accessibilityLabel = "Cell Label"
            contentView.addSubview(label)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    class MockCollectionView: UICollectionView, UICollectionViewDataSource {
        init(cellCount: Int) {
            let layout = UICollectionViewFlowLayout()
            layout.itemSize = CGSize(width: 50, height: 50)
            super.init(frame: .zero, collectionViewLayout: layout)
            dataSource = self
            register(MockCell.self, forCellWithReuseIdentifier: "Cell")
            self.cellCount = cellCount
        }

        var cellCount: Int = 0

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            cellCount
        }

        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        }
    }

    class MockAccessibleView: UIView {
        init(label: String, frame: CGRect) {
            super.init(frame: frame)
            isAccessibilityElement = true
            accessibilityLabel = label
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
