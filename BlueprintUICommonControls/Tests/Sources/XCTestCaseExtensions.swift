import BlueprintUI
import XCTest


extension XCTestCase {

    func compareSnapshot(
        of image: UIImage,
        identifier: String? = nil,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {

        // Get image URL

        var imageURL = URL(fileURLWithPath: "\(file)")
        imageURL.deletePathExtension()

        let filename = imageURL.lastPathComponent

        imageURL.deleteLastPathComponent()
        imageURL.appendPathComponent("Resources", isDirectory: true)
        imageURL.appendPathComponent("ReferenceImages", isDirectory: true)
        imageURL.appendPathComponent(filename, isDirectory: true)

        // Make sure the directory exists
        do {
            try FileManager.default.createDirectory(
                at: imageURL,
                withIntermediateDirectories: true,
                attributes: [:]
            )
        } catch (let error) {
            XCTFail("Failed to create directory for snapshot image: \(error)", file: file, line: line)
        }


        let testName = testName.prefix(testName.count - 2)
        let majorVersion = ProcessInfo.processInfo.operatingSystemVersion.majorVersion
        imageURL.appendPathComponent("\(testName)_\(identifier ?? "")_iOS-\(majorVersion).png")

        if let referenceImage = UIImage(contentsOfFile: imageURL.path) {
            if referenceImage.pixelData == image.pixelData {
                // Success!
                return
            } else {
                XCTFail("Snapshot did not match reference image", file: file, line: line)
            }
        } else {
            XCTFail("Failed to load reference image: \(imageURL.path)", file: file, line: line)
        }



        guard let pngData = image.pngData() else {
            XCTFail("Failed to get PNG data for snapshot image", file: file, line: line)
            return
        }

        do {
            try pngData.write(to: imageURL)
        } catch (let error) {
            XCTFail("Failed to write snapshot image: \(error)", file: file, line: line)
        }

    }

    func compareSnapshot(
        of view: UIView,
        identifier: String? = nil,
        scale: CGFloat = 1,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {

        view.layoutIfNeeded()

        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, scale)

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

    func compareSnapshot(
        of element: Element,
        size: CGSize? = nil,
        identifier: String? = nil,
        scale: CGFloat = 1,
        layoutModes: [LayoutMode] = LayoutMode.testModes,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        for layoutMode in layoutModes {
            let view = BlueprintView(element: element)
            view.name = "Snapshot Host"
            view.layoutMode = layoutMode

            if let size = size {
                view.frame = CGRect(origin: .zero, size: size)
            } else {
                view.sizeToFit()
                view.frame.size.width.round(.up, by: scale)
                view.frame.size.height.round(.up, by: scale)
            }

            compareSnapshot(
                of: view,
                identifier: identifier,
                scale: scale,
                file: file,
                testName: testName,
                line: line
            )
        }
    }

}



extension UIImage {

    var pixelData: [UInt8] {
        let size = CGSize(
            width: size.width * scale,
            height: size.height * scale
        )
        let dataSize = size.width * size.height * 4
        var pixelData = [UInt8](repeating: 0, count: Int(dataSize))
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: &pixelData,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: 4 * Int(size.width),
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        )
        guard let cgImage = cgImage else { return [] }
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))

        return pixelData
    }
}

extension XCTestCase {
    /// Run the given block with a window that is key and visible, then releases it.
    func withWindow(block: (UIWindow) -> Void) {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.makeKeyAndVisible()

        block(window)

        window.isHidden = true
        window.windowScene = nil
    }
}

extension XCTestCase {

    /// Allows waiting for asynchronous work to complete within a test method by
    /// spinning the main runloop until the `predicate` returns true.
    public func waitFor(
        timeout: TimeInterval = 10.0,
        predicate: () throws -> Bool,
        error: (() -> String)? = nil
    ) rethrows {
        let runloop = RunLoop.main
        let timeout = Date(timeIntervalSinceNow: timeout)

        while Date() < timeout {
            if try predicate() {
                return
            }

            runloop.run(mode: .default, before: Date(timeIntervalSinceNow: 0.001))
        }

        if let error = error {
            XCTFail("waitUntil timed out waiting for a check to pass. Error: \(error())")
        } else {
            XCTFail("waitUntil timed out waiting for a check to pass.")
        }
    }
}
