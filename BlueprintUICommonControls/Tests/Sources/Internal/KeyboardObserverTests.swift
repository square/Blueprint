import UIKit
import XCTest

@testable import BlueprintUICommonControls


class KeyboardObserverTests: XCTestCase {

    func test_add() {
        let center = NotificationCenter()
        let observer = KeyboardObserver(center: center)

        var delegate1: Delegate? = Delegate()
        weak var weakDelegate1 = delegate1

        let delegate2 = Delegate()
        let delegate3 = Delegate()

        // Validate that delegates are only registered once.

        XCTAssertEqual(observer.delegates.count, 0)

        observer.add(delegate: delegate1!)
        XCTAssertEqual(observer.delegates.count, 1)

        observer.add(delegate: delegate1!)
        XCTAssertEqual(observer.delegates.count, 1)

        // Register a second observer

        observer.add(delegate: delegate2)
        XCTAssertEqual(observer.delegates.count, 2)

        // Register a third, but deallocate the first. Should be removed.

        delegate1 = nil

        waitFor {
            weakDelegate1 == nil
        }

        observer.add(delegate: delegate3)
        XCTAssertEqual(observer.delegates.count, 2)
    }

    func test_remove() {
        let center = NotificationCenter()
        let observer = KeyboardObserver(center: center)

        let delegate1: Delegate? = Delegate()

        var delegate2: Delegate? = Delegate()
        weak var weakDelegate2 = delegate2

        let delegate3: Delegate? = Delegate()

        // Register all 3 observers

        observer.add(delegate: delegate1!)
        observer.add(delegate: delegate2!)
        observer.add(delegate: delegate3!)

        XCTAssertEqual(observer.delegates.count, 3)

        // Nil out the second delegate

        delegate2 = nil

        waitFor {
            weakDelegate2 == nil
        }

        // Should only have 1 left

        observer.remove(delegate: delegate3!)
        XCTAssertEqual(observer.delegates.count, 1)
    }

    func test_notifications() {
        let center = NotificationCenter()

        // Will Change Frame
        do {
            let observer = KeyboardObserver(center: center)

            let delegate = Delegate()
            observer.add(delegate: delegate)

            let userInfo: [AnyHashable: Any] = [
                UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: CGRect(
                    x: 10.0,
                    y: 10.0,
                    width: 100.0,
                    height: 200.0
                )),
                UIResponder.keyboardAnimationDurationUserInfoKey: NSNumber(value: 2.5),
                UIResponder.keyboardAnimationCurveUserInfoKey: NSNumber(value: 123),
            ]

            XCTAssertEqual(delegate.keyboardFrameWillChange_callCount, 0)
            center.post(Notification(
                name: UIWindow.keyboardWillChangeFrameNotification,
                object: UIScreen.main,
                userInfo: userInfo
            ))
            XCTAssertEqual(delegate.keyboardFrameWillChange_callCount, 1)
        }

        // Did Change Frame
        do {
            let observer = KeyboardObserver(center: center)

            let delegate = Delegate()
            observer.add(delegate: delegate)

            let userInfo: [AnyHashable: Any] = [
                UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: CGRect(
                    x: 10.0,
                    y: 10.0,
                    width: 100.0,
                    height: 200.0
                )),
                UIResponder.keyboardAnimationDurationUserInfoKey: NSNumber(value: 2.5),
                UIResponder.keyboardAnimationCurveUserInfoKey: NSNumber(value: 123),
            ]

            XCTAssertEqual(delegate.keyboardFrameWillChange_callCount, 0)
            center.post(Notification(
                name: UIWindow.keyboardDidChangeFrameNotification,
                object: UIScreen.main,
                userInfo: userInfo
            ))
            XCTAssertEqual(delegate.keyboardFrameWillChange_callCount, 1)
        }

        // Only calls delegate for changed frame
        do {
            let observer = KeyboardObserver(center: center)

            let delegate = Delegate()
            observer.add(delegate: delegate)

            let userInfo: [AnyHashable: Any] = [
                UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: CGRect(
                    x: 10.0,
                    y: 10.0,
                    width: 100.0,
                    height: 200.0
                )),
                UIResponder.keyboardAnimationDurationUserInfoKey: NSNumber(value: 2.5),
                UIResponder.keyboardAnimationCurveUserInfoKey: NSNumber(value: 123),
            ]

            XCTAssertEqual(delegate.keyboardFrameWillChange_callCount, 0)
            center.post(Notification(
                name: UIWindow.keyboardDidChangeFrameNotification,
                object: UIScreen.main,
                userInfo: userInfo
            ))
            XCTAssertEqual(delegate.keyboardFrameWillChange_callCount, 1)

            XCTAssertEqual(delegate.keyboardFrameWillChange_callCount, 1)
            center.post(Notification(
                name: UIWindow.keyboardDidChangeFrameNotification,
                object: UIScreen.main,
                userInfo: userInfo
            ))
            XCTAssertEqual(delegate.keyboardFrameWillChange_callCount, 1)
        }
    }

    final class Delegate: KeyboardObserverDelegate {

        var keyboardFrameWillChange_callCount: Int = 0

        func keyboardFrameWillChange(
            for observer: KeyboardObserver,
            animationDuration: Double,
            animationCurve: UIView.AnimationCurve
        ) {

            keyboardFrameWillChange_callCount += 1
        }
    }
}


class KeyboardObserver_NotificationInfo_Tests: XCTestCase {

    func test_init() {

        let defaultUserInfo: [AnyHashable: Any] = [
            UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: CGRect(
                x: 10.0,
                y: 10.0,
                width: 100.0,
                height: 200.0
            )),
            UIResponder.keyboardAnimationDurationUserInfoKey: NSNumber(value: 2.5),
            UIResponder.keyboardAnimationCurveUserInfoKey: NSNumber(value: 123),
        ]

        // Successful Init
        do {
            let info = try! KeyboardObserver.NotificationInfo(
                with: Notification(
                    name: UIResponder.keyboardDidShowNotification,
                    object: UIScreen.main,
                    userInfo: defaultUserInfo
                )
            )

            XCTAssertEqual(info.endingFrame, CGRect(x: 10.0, y: 10.0, width: 100.0, height: 200.0))
            XCTAssertEqual(info.animationDuration, 2.5)
            XCTAssertEqual(info.animationCurve, UIView.AnimationCurve(rawValue: 123)!)
        }

        // Failed Inits
        do {
            // No userInfo
            do {
                XCTAssertThrowsError(
                    try _ = KeyboardObserver.NotificationInfo(
                        with: Notification(
                            name: UIResponder.keyboardDidShowNotification,
                            object: UIScreen.main,
                            userInfo: nil
                        )
                    )
                ) { error in
                    XCTAssertEqual(error as? KeyboardObserver.NotificationInfo.ParseError, .missingUserInfo)
                }
            }

            // No end frame
            do {
                var userInfo = defaultUserInfo
                userInfo.removeValue(forKey: UIResponder.keyboardFrameEndUserInfoKey)

                XCTAssertThrowsError(
                    try _ = KeyboardObserver.NotificationInfo(
                        with: Notification(
                            name: UIResponder.keyboardDidShowNotification,
                            object: UIScreen.main,
                            userInfo: userInfo
                        )
                    )
                ) { error in
                    XCTAssertEqual(error as? KeyboardObserver.NotificationInfo.ParseError, .missingEndingFrame)
                }
            }

            // No animation duration
            do {
                var userInfo = defaultUserInfo
                userInfo.removeValue(forKey: UIResponder.keyboardAnimationDurationUserInfoKey)

                XCTAssertThrowsError(
                    try _ = KeyboardObserver.NotificationInfo(
                        with: Notification(
                            name: UIResponder.keyboardDidShowNotification,
                            object: UIScreen.main,
                            userInfo: userInfo
                        )
                    )
                ) { error in
                    XCTAssertEqual(error as? KeyboardObserver.NotificationInfo.ParseError, .missingAnimationDuration)
                }
            }

            // No animation curve
            do {
                var userInfo = defaultUserInfo
                userInfo.removeValue(forKey: UIResponder.keyboardAnimationCurveUserInfoKey)

                XCTAssertThrowsError(
                    try KeyboardObserver.NotificationInfo(
                        with: Notification(
                            name: UIResponder.keyboardDidShowNotification,
                            object: UIScreen.main,
                            userInfo: userInfo
                        )
                    )
                ) { error in
                    XCTAssertEqual(error as? KeyboardObserver.NotificationInfo.ParseError, .missingAnimationCurve)
                }
            }
        }
    }
}
