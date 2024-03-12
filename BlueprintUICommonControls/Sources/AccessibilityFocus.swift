import BlueprintUI
import UIKit

/// Enables VoiceOver focus to jump to the wrapped element via a trigger that can be manually fired.
public struct AccessibilityFocus: Element {

    /// The element that will have the focus.
    public var wrapped: Element

    /// A object that can be held on to by the caller to manually trigger a focus.
    public var trigger: Trigger

    /// Creates a new `AccessibilityFocus` wrapping the provided element.
    public init(
        wrapping wrapped: Element,
        trigger: Trigger
    ) {
        self.wrapped = wrapped
        self.trigger = trigger
    }

    // MARK: Element

    public var content: ElementContent {
        ElementContent(child: wrapped)
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        View.describe { config in
            config.apply { view in
                view.apply(model: self)
            }
        }
    }
}

// MARK: Backing view

extension AccessibilityFocus {


    private final class View: UIView {

        private var trigger: Trigger?

        func apply(model: AccessibilityFocus) {
            trigger?.action = nil
            trigger = model.trigger
            model.trigger.action = { [weak self] in
                guard let self = self else { return }
                UIAccessibility.post(notification: model.trigger.notificationType, argument: self)
            }
        }

        override var isAccessibilityElement: Bool {
            get { false }
            set {}
        }
    }
}

// MARK: Trigger

extension AccessibilityFocus {

    /// A trigger that can be used to manually fire an accessibility focus.
    public final class Trigger {

        /// The type of accessibility notification that will be triggered.
        public var notificationType: UIAccessibility.Notification

        /// An optional identifier for the trigger.
        public var identifier: AnyHashable?

        /// Creates a new trigger for the purpose of changing accessibility focus.
        /// - Parameters:
        ///   - notificationType: Type of accessibility notification to trigger. Defaults to `.layoutChanged`. Limited to `.layoutChanged` or `.screenChanged`.
        ///   - identifier: An optional identifier for the trigger. Defaults to `nil`.
        public init(
            notificationType: UIAccessibility.Notification = .layoutChanged,
            identifier: AnyHashable? = nil
        ) {
            self.notificationType = notificationType
            self.identifier = identifier
        }

        fileprivate var action: (() -> Void)?

        /// Manually fire the trigger
        public func focus() {
            action?()
        }
    }
}

extension Element {

    /// Enables VoiceOver focus to jump to the wrapped element via the trigger.
    /// - Parameters:
    ///   - on: A reference-type trigger object that can be used to trigger accessibility focus via the `focus()` function.
    public func accessibilityFocus(
        on trigger: AccessibilityFocus.Trigger
    ) -> Element {
        AccessibilityFocus(
            wrapping: self,
            trigger: trigger
        )
    }
}
