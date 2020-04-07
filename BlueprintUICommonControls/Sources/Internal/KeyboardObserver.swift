//
//  KeyboardObserver.swift
//  BlueprintUICommonControls
//
//  Created by Kyle Van Essen on 2/16/20.
//

import UIKit


protocol KeyboardObserverDelegate : AnyObject {
    
    func keyboardFrameWillChange(
        for observer : KeyboardObserver,
        animationDuration : Double,
        options : UIView.AnimationOptions
    )
}

/**
 Encapsulates listening for system keyboard updates, plus transforming the visible frame of the keyboard into the coordinates of a requested view.
 
 You use this class by providing a delegate, which receives callbacks when changes to the keyboard frame occur. You would usually implement
 the delegate somewhat like this:
 
 ```
 func keyboardFrameWillChange(
     for observer : KeyboardObserver,
     animationDuration : Double,
     options : UIView.AnimationOptions
 ) {
     UIView.animate(withDuration: animationDuration, delay: 0.0, options: options, animations: {
         // Use the frame from the keyboardObserver to update insets or sizing where relevant.
     })
 }
 ```
 
 Notes
 -----
 Implementation borrowed from Listable:
 https://github.com/kyleve/Listable/blob/master/Listable/Sources/Internal/KeyboardObserver.swift
 
 iOS Docs for keyboard management:
 https://developer.apple.com/library/archive/documentation/StringsTextFonts/Conceptual/TextAndWebiPhoneOS/KeyboardManagement/KeyboardManagement.html
 */
final class KeyboardObserver {
    
    private let center : NotificationCenter
    
    weak var delegate : KeyboardObserverDelegate?
    
    //
    // MARK: Initialization
    //
    
    init(center : NotificationCenter = .default) {
        
        self.center = center
        
        /// We need to listen to both `will` and `keyboardDidChangeFrame` notifications. Why?
        /// When dealing with an undocked or floating keyboard, moving the keyboard
        /// around the screen does NOT call `willChangeFrame`; only `didChangeFrame` is called.
        /// Before calling the delegate, we compare `old.endingFrame != new.endingFrame`,
        /// which ensures that the delegate is notified if the frame really changes, and
        /// prevents duplicate calls.

        self.center.addObserver(self, selector: #selector(keyboardFrameChanged(_:)), name: UIWindow.keyboardWillChangeFrameNotification, object: nil)
        self.center.addObserver(self, selector: #selector(keyboardFrameChanged(_:)), name: UIWindow.keyboardDidChangeFrameNotification, object: nil)
    }
    
    private var latestNotification : NotificationInfo?
    
    //
    // MARK: Handling Changes
    //
    
    enum KeyboardFrame : Equatable {
        
        /// The current frame does not overlap the current view at all.
        case nonOverlapping
        
        /// The current frame does overlap the view, by the provided rect, in the view's coordinate space.
        case overlapping(frame: CGRect)
    }
    
    /// How the keyboard overlaps the view provided. If the view is not on screen (eg, no window),
    /// or the observer has not yet learned about the keyboard's position, this method returns nil.
    func currentFrame(in view : UIView) -> KeyboardFrame? {
        
        guard view.window != nil else {
            return nil
        }
        
        guard let notification = self.latestNotification else {
            return nil
        }
        
        let frame = view.convert(notification.endingFrame, from: nil)
        
        if frame.intersects(view.bounds) {
            return .overlapping(frame: frame)
        } else {
            return .nonOverlapping
        }
    }
    
    //
    // MARK: Receiving Updates
    //
    
    private func receivedUpdatedKeyboardInfo(_ new : NotificationInfo) {
        
        let old = self.latestNotification
        
        self.latestNotification = new
        
        /// Only communicate a frame change to the delegate if the frame actually changed.
        
        if let old = old, old.endingFrame == new.endingFrame {
            return
        }
                
        /**
         Create an animation curve with the correct curve for showing or hiding the keyboard.
         
         This is unfortunately a private UIView curve. However, we can map it to the animation options' curve
         like so: https://stackoverflow.com/questions/26939105/keyboard-animation-curve-as-int
         */
        let animationOptions = UIView.AnimationOptions(rawValue: new.animationCurve << 16)
        
        self.delegate?.keyboardFrameWillChange(
            for: self,
            animationDuration: new.animationDuration,
            options: animationOptions
        )
    }
    
    //
    // MARK: Notification Listeners
    //
    
    @objc private func keyboardFrameChanged(_ notification : Notification) {
        
        do {
            let info = try NotificationInfo(with: notification)
            self.receivedUpdatedKeyboardInfo(info)
        } catch {
            assertionFailure("Blueprint could not read system keyboard notification. This error needs to be fixed in Blueprint. Error: \(error)")
        }
    }
}

extension KeyboardObserver
{
    struct NotificationInfo : Equatable {
        
        var endingFrame : CGRect = .zero
        
        var animationDuration : Double = 0.0
        var animationCurve : UInt = 0
        
        init(with notification : Notification) throws {
            
            guard let userInfo = notification.userInfo else {
                throw ParseError.missingUserInfo
            }
            
            guard let endingFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
                throw ParseError.missingEndingFrame
            }
            
            self.endingFrame = endingFrame
            
            guard let animationDuration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue else {
                throw ParseError.missingAnimationDuration
            }
            
            self.animationDuration = animationDuration
            
            guard let animationCurve = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue else {
                throw ParseError.missingAnimationCurve
            }
            
            self.animationCurve = animationCurve
        }
        
        enum ParseError : Error, Equatable {
            
            case missingUserInfo
            case missingEndingFrame
            case missingAnimationDuration
            case missingAnimationCurve
        }
    }
}
