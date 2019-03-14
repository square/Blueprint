import XCTest
import Blueprint
import SnapshotTesting


extension XCTestCase {

    func compareSnapshot(of image: UIImage, identifier: String? = nil, file: StaticString = #file, testName: String = #function, line: UInt = #line) {
        assertSnapshot(matching: image, as: .image, named: identifier, file: file, testName: testName, line: line)
    }

    func compareSnapshot(of view: UIView, identifier: String? = nil, file: StaticString = #file, testName: String = #function, line: UInt = #line) {

        view.layoutIfNeeded()

        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, 0)

        guard let context = UIGraphicsGetCurrentContext() else {
            XCTFail("Failed to get graphics context", file: file, line: line)
            return
        }

        view.layer.render(in: context)

        guard let image = UIGraphicsGetImageFromCurrentImageContext() else {
            XCTFail("Failed to get snapshot image from view", file: file, line: line)
            return
        }

        UIGraphicsEndImageContext()

        compareSnapshot(of: image, identifier: identifier, file: file, testName: testName, line: line)
    }

    func compareSnapshot(of element: Element, size: CGSize? = nil, identifier: String? = nil, file: StaticString = #file, testName: String = #function, line: UInt = #line) {
        let view = BlueprintView(element: element)

        if let size = size {
            view.frame = CGRect(origin: .zero, size: size)
        } else {
            view.sizeToFit()
        }

        compareSnapshot(of: view, identifier: identifier, file: file, testName: testName, line: line)
    }

}
