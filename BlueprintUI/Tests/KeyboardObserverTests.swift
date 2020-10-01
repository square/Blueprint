import XCTest
import UIKit

@testable import BlueprintUICommonControls


class KeyboardObserverTests: XCTestCase {
    
    func test_notifications() {
        let center = NotificationCenter()
        
        // Will Change Frame
        do {
            let observer = KeyboardObserver(center: center)

            let delegate = Delegate()
            observer.delegate = delegate
            
            let userInfo : [AnyHashable:Any] = [
                UIResponder.keyboardFrameEndUserInfoKey : NSValue(cgRect: CGRect(x: 10.0, y: 10.0, width: 100.0, height: 200.0)),
                UIResponder.keyboardAnimationDurationUserInfoKey : NSNumber(value: 2.5),
                UIResponder.keyboardAnimationCurveUserInfoKey : NSNumber(value: 123)
            ]
            
            XCTAssertEqual(delegate.keyboardFrameWillChange_callCount, 0)
            center.post(Notification(name: UIWindow.keyboardWillChangeFrameNotification, object: nil, userInfo: userInfo))
            XCTAssertEqual(delegate.keyboardFrameWillChange_callCount, 1)
        }
        
        // Did Change Frame
        do {
            let observer = KeyboardObserver(center: center)

            let delegate = Delegate()
            observer.delegate = delegate
            
            let userInfo : [AnyHashable:Any] = [
                UIResponder.keyboardFrameEndUserInfoKey : NSValue(cgRect: CGRect(x: 10.0, y: 10.0, width: 100.0, height: 200.0)),
                UIResponder.keyboardAnimationDurationUserInfoKey : NSNumber(value: 2.5),
                UIResponder.keyboardAnimationCurveUserInfoKey : NSNumber(value: 123)
            ]
            
            XCTAssertEqual(delegate.keyboardFrameWillChange_callCount, 0)
            center.post(Notification(name: UIWindow.keyboardDidChangeFrameNotification, object: nil, userInfo: userInfo))
            XCTAssertEqual(delegate.keyboardFrameWillChange_callCount, 1)
        }
        
        // Only calls delegate for changed frame
        do {
            let observer = KeyboardObserver(center: center)

             let delegate = Delegate()
             observer.delegate = delegate
             
             let userInfo : [AnyHashable:Any] = [
                 UIResponder.keyboardFrameEndUserInfoKey : NSValue(cgRect: CGRect(x: 10.0, y: 10.0, width: 100.0, height: 200.0)),
                 UIResponder.keyboardAnimationDurationUserInfoKey : NSNumber(value: 2.5),
                 UIResponder.keyboardAnimationCurveUserInfoKey : NSNumber(value: 123)
             ]
             
             XCTAssertEqual(delegate.keyboardFrameWillChange_callCount, 0)
             center.post(Notification(name: UIWindow.keyboardDidChangeFrameNotification, object: nil, userInfo: userInfo))
             XCTAssertEqual(delegate.keyboardFrameWillChange_callCount, 1)
             
             XCTAssertEqual(delegate.keyboardFrameWillChange_callCount, 1)
             center.post(Notification(name: UIWindow.keyboardDidChangeFrameNotification, object: nil, userInfo: userInfo))
             XCTAssertEqual(delegate.keyboardFrameWillChange_callCount, 1)
        }
    }
    
    final class Delegate : KeyboardObserverDelegate {
        
        var keyboardFrameWillChange_callCount : Int = 0
        
        func keyboardFrameWillChange(for observer: KeyboardObserver, animationDuration: Double, options: UIView.AnimationOptions) {
            
            self.keyboardFrameWillChange_callCount += 1
        }
    }
}


class KeyboardObserver_NotificationInfo_Tests : XCTestCase {
    
    func test_init() {
        
        let defaultUserInfo : [AnyHashable:Any] = [
            UIResponder.keyboardFrameEndUserInfoKey : NSValue(cgRect: CGRect(x: 10.0, y: 10.0, width: 100.0, height: 200.0)),
            UIResponder.keyboardAnimationDurationUserInfoKey : NSNumber(value: 2.5),
            UIResponder.keyboardAnimationCurveUserInfoKey : NSNumber(value: 123)
        ]
        
        // Successful Init
        do {
            let info = try! KeyboardObserver.NotificationInfo(
                with: Notification(name: UIResponder.keyboardDidShowNotification, object: nil, userInfo: defaultUserInfo)
            )

            XCTAssertEqual(info.endingFrame, CGRect(x: 10.0, y: 10.0, width: 100.0, height: 200.0))
            XCTAssertEqual(info.animationDuration, 2.5)
            XCTAssertEqual(info.animationCurve, 123)
        }
        
        // Failed Inits
        do {
            // No userInfo
            do {
                XCTAssertThrowsError(
                    try _ = KeyboardObserver.NotificationInfo(
                        with: Notification(name: UIResponder.keyboardDidShowNotification, object: nil, userInfo: nil)
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
                        with: Notification(name: UIResponder.keyboardDidShowNotification, object: nil, userInfo: userInfo)
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
                        with: Notification(name: UIResponder.keyboardDidShowNotification, object: nil, userInfo: userInfo)
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
                        with: Notification(name: UIResponder.keyboardDidShowNotification, object: nil, userInfo: userInfo)
                    )
                ) { error in
                    XCTAssertEqual(error as? KeyboardObserver.NotificationInfo.ParseError, .missingAnimationCurve)
                }
            }
        }
    }
}
