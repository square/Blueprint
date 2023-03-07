//
//  KeyboardObserver.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 2/16/20.
//

import UIKit


/// Provides callbacks when the `KeyboardObserver`'s observed keyboard frame
/// changes. You can use the provided `animationDuration` and `options`
/// to animate any changes you require alongside the keyboard:
/// ```
/// func keyboardFrameWillChange(
///     for observer : KeyboardObserver,
///     animationDuration : Double,
///     options : UIView.AnimationOptions
/// ) {
///     UIView.animate(withDuration: animationDuration, delay: 0.0, options: options, animations: {
///         // But your animations in here.
///     })
/// }
/// ```
@_spi(BlueprintKeyboardObserver) public protocol KeyboardObserverDelegate: AnyObject {

    func keyboardFrameWillChange(
        for observer: KeyboardObserver,
        animationDuration: Double,
        options: UIView.AnimationOptions
    )
}


/// The possible states of a keyboard as monitored by the `KeyboardObserver`.
public enum KeyboardFrame: Equatable {

    /// The current frame does not overlap the current view at all.
    case nonOverlapping

    /// The current frame does overlap the view, by the provided rect, in the view's coordinate space.
    case overlapping(frame: CGRect)

    var frame: CGRect? {
        switch self {
        case .nonOverlapping:
            return nil
        case .overlapping(let frame):
            return frame
        }
    }
}

/**
 Encapsulates listening for system keyboard updates, plus transforming the visible frame of the keyboard into the coordinates of a requested view.

 You use this class by providing a delegate, which receives callbacks when changes to the keyboard frame occur.

 Notes
 -----
 iOS Docs for keyboard management:
 https://developer.apple.com/library/archive/documentation/StringsTextFonts/Conceptual/TextAndWebiPhoneOS/KeyboardManagement/KeyboardManagement.html
 */
@_spi(BlueprintKeyboardObserver) public final class KeyboardObserver {

    /// The global shared keyboard observer. Why is it a global shared instance?
    /// We can only know the keyboard position via the keyboard frame notifications.
    ///
    /// If a view is created while a keyboard is already on-screen, we'd have
    /// no way to determine the keyboard frame, and thus couldn't provide the correct
    /// content insets to avoid the visible keyboard.
    ///
    /// Thus, the `shared` observer is set up the first time a view that needs to know about the
    /// keyboard is created, to ensure later views have keyboard information.
    ///
    /// To ensure that the keyboard is always being observed, it is recommended that
    /// you call `BlueprintView.beginObservingKeyboard()` within your
    /// application or view controller, before the first `BlueprintView` is presented on screen,
    /// if you are utilizing `KeyboardReader` or `KeyboardObserver` within your application.
    public static let shared: KeyboardObserver = KeyboardObserver(center: .default)

    public let center: NotificationCenter

    private(set) var delegates: [Delegate] = []

    struct Delegate {
        private(set) weak var value: KeyboardObserverDelegate?
    }

    //
    // MARK: Initialization
    //

    init(center: NotificationCenter) {

        self.center = center

        /// We need to listen to both `will` and `keyboardDidChangeFrame` notifications. Why?
        ///
        /// When dealing with an undocked or floating keyboard, moving the keyboard
        /// around the screen does NOT call `willChangeFrame`; only `didChangeFrame` is called.
        ///
        /// Before calling the delegate, we compare `old.endingFrame != new.endingFrame`,
        /// which ensures that the delegate is notified if the frame really changes, and
        /// prevents duplicate calls.

        self.center.addObserver(
            self,
            selector: #selector(keyboardFrameChanged(_:)),
            name: UIWindow.keyboardWillChangeFrameNotification,
            object: nil
        )
        self.center.addObserver(
            self,
            selector: #selector(keyboardFrameChanged(_:)),
            name: UIWindow.keyboardDidChangeFrameNotification,
            object: nil
        )
    }

    private var latestNotification: NotificationInfo?

    //
    // MARK: Delegates
    //

    /// Adds the given `delegate`, so it will begin recieving updates when the keyboard frame changes.
    /// If the `delegate` is already observing, this method has no effect.
    public func add(delegate: KeyboardObserverDelegate) {

        if delegates.contains(where: { $0.value === delegate }) {
            return
        }

        delegates.append(Delegate(value: delegate))

        removeDeallocatedDelegates()
    }

    /// Removes the given `delegate`, so it will stop recieving updates when the keyboard frame changes.
    /// If the `delegate` is not observing, this method has no effect.
    public func remove(delegate: KeyboardObserverDelegate) {
        delegates.removeAll {
            $0.value === delegate
        }

        removeDeallocatedDelegates()
    }

    private func removeDeallocatedDelegates() {
        delegates.removeAll {
            $0.value == nil
        }
    }

    //
    // MARK: Handling Changes
    //

    /// How the keyboard overlaps the view provided. If the view is not on screen (eg, no window),
    /// or the observer has not yet learned about the keyboard's position, this method returns nil.
    public func currentFrame(in view: UIView) -> KeyboardFrame? {

        guard view.window != nil else {
            return nil
        }

        guard let notification = latestNotification else {
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

    private func receivedUpdatedKeyboardInfo(_ new: NotificationInfo) {

        let old = latestNotification

        latestNotification = new

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

        delegates.forEach {
            $0.value?.keyboardFrameWillChange(
                for: self,
                animationDuration: new.animationDuration,
                options: animationOptions
            )
        }
    }

    //
    // MARK: Notification Listeners
    //

    @objc private func keyboardFrameChanged(_ notification: Notification) {

        do {
            let info = try NotificationInfo(with: notification)
            receivedUpdatedKeyboardInfo(info)
        } catch {
            assertionFailure("Blueprint could not read system keyboard notification. This error needs to be fixed in Blueprint. Error: \(error)")
        }
    }
}


extension BlueprintView {

    ///
    /// Begins observing system notifications to track the position of the keyboard.
    ///
    /// To ensure that the keyboard is always being observed, it is recommended that
    /// you call `BlueprintView.beginObservingKeyboard()` within your
    /// application or view controller, before the first `BlueprintView` is presented on screen,
    /// if you are utilizing `KeyboardReader` or `KeyboardObserver` within your application.
    public static func beginObservingKeyboard() {
        _ = KeyboardObserver.shared
    }
}


extension KeyboardObserver {
    struct NotificationInfo: Equatable {

        var endingFrame: CGRect = .zero

        var animationDuration: Double = 0.0
        var animationCurve: UInt = 0

        init(with notification: Notification) throws {

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

        enum ParseError: Error, Equatable {

            case missingUserInfo
            case missingEndingFrame
            case missingAnimationDuration
            case missingAnimationCurve
        }
    }
}
