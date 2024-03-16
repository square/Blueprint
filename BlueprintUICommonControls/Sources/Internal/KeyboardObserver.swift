import UIKit


protocol KeyboardObserverDelegate: AnyObject {

    func keyboardFrameWillChange(
        for observer: KeyboardObserver,
        animationDuration: Double,
        animationCurve: UIView.AnimationCurve
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
 iOS Docs for keyboard management:
 https://developer.apple.com/library/archive/documentation/StringsTextFonts/Conceptual/TextAndWebiPhoneOS/KeyboardManagement/KeyboardManagement.html
 */
final class KeyboardObserver {

    /// The global shared keyboard observer. Why is it a global shared instance?
    /// We can only know the keyboard position via the keyboard frame notifications.
    ///
    /// If a keyboard observing view is created while a keyboard is already on-screen, we'd have no way to determine the
    /// keyboard frame, and thus couldn't provide the correct content insets to avoid the visible keyboard.
    ///
    /// Thus, the `shared` observer is set up on app startup
    /// (see `SetupKeyboardObserverOnAppStartup.m`) to avoid this problem.
    static let shared: KeyboardObserver = KeyboardObserver(center: .default)

    /// Allow logging to the console if app startup-timed shared instance startup did not
    /// occur; this could cause bugs for the reasons outlined above.
    fileprivate static var didSetupSharedInstanceDuringAppStartup = false

    private let center: NotificationCenter

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

    func add(delegate: KeyboardObserverDelegate) {

        if delegates.contains(where: { $0.value === delegate }) {
            return
        }

        delegates.append(Delegate(value: delegate))

        removeDeallocatedDelegates()
    }

    func remove(delegate: KeyboardObserverDelegate) {
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

    enum KeyboardFrame: Equatable {

        /// The current frame does not overlap the current view at all.
        case nonOverlapping

        /// The current frame does overlap the view, by the provided rect, in the view's coordinate space.
        case overlapping(frame: CGRect)
    }

    /// How the keyboard overlaps the view provided. If the view is not on screen (eg, no window),
    /// or the observer has not yet learned about the keyboard's position, this method returns nil.
    func currentFrame(in view: UIView) -> KeyboardFrame? {

        guard let window = view.window else {
            return nil
        }

        guard let notification = latestNotification else {
            return nil
        }

        let screen = notification.screen ?? window.screen

        let frame = screen.coordinateSpace.convert(
            notification.endingFrame,
            to: view
        )

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

        delegates.forEach {
            $0.value?.keyboardFrameWillChange(
                for: self,
                animationDuration: new.animationDuration,
                animationCurve: new.animationCurve
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
            assertionFailure("Could not read system keyboard notification: \(error)")
        }
    }
}

extension KeyboardObserver {
    struct NotificationInfo: Equatable {

        var endingFrame: CGRect = .zero

        var animationDuration: Double = 0.0
        var animationCurve: UIView.AnimationCurve = .easeInOut

        /// The `UIScreen` that the keyboard appears on.
        ///
        /// This may influence the `KeyboardFrame` calculation when the app is not in full screen,
        /// such as in Split View, Slide Over, and Stage Manager.
        ///
        /// - note: In iOS 16.1 and later, every `keyboardWillChangeFrameNotification` and
        /// `keyboardDidChangeFrameNotification` is _supposed_ to include a `UIScreen`
        /// in a the notification, however we've had reports that this isn't always the case (at least when
        /// using the iOS 16.1 simulator runtime). If a screen is _not_ included in an iOS 16.1+ notification,
        /// we do not throw a `ParseError` as it would cause the entire notification to be discarded.
        ///
        /// [Apple Documentation](https://developer.apple.com/documentation/uikit/uiresponder/1621623-keyboardwillchangeframenotificat)
        var screen: UIScreen?

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

            guard let curveValue = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.intValue,
                  let animationCurve = UIView.AnimationCurve(rawValue: curveValue)
            else {
                throw ParseError.missingAnimationCurve
            }

            self.animationCurve = animationCurve

            screen = notification.object as? UIScreen
        }

        enum ParseError: Error, Equatable {

            case missingUserInfo
            case missingEndingFrame
            case missingAnimationDuration
            case missingAnimationCurve
        }
    }
}


extension KeyboardObserver {
    private static let isExtensionContext: Bool = {
        // This is our best guess for "is this executable an extension?"
        if let _ = Bundle.main.infoDictionary?["NSExtension"] {
            return true
        } else if Bundle.main.bundlePath.hasSuffix(".appex") {
            return true
        } else {
            return false
        }
    }()

    /// This should be called by a keyboard-observing view on setup, to warn developers if something has gone wrong with
    /// keyboard setup.
    static func logKeyboardSetupWarningIfNeeded() {
        guard !isExtensionContext else {
            return
        }

        if KeyboardObserver.didSetupSharedInstanceDuringAppStartup {
            return
        }

        print(
            """
            WARNING: The shared instance of the `KeyboardObserver` was not instantiated during
            app startup. While not fatal, this could result in a view being created that does
            not properly position itself to account for the keyboard, if the view is created
            while the keyboard is already visible.
            """
        )
    }
}

