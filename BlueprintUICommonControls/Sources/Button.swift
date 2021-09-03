import BlueprintUI
import UIKit


/// An element that wraps a child element in a button that mimics a UIButton with the .system style. That is, when
/// highlighted (or disabled), it fades its contents to partial alpha.
public struct Button: Element {

    public var wrappedElement: Element
    public var isEnabled: Bool
    public var onTap: () -> Void
    public var minimumTappableSize: CGSize = CGSize(width: 44, height: 44)

    public init(isEnabled: Bool = true, onTap: @escaping () -> Void = {}, wrapping element: Element) {
        wrappedElement = element
        self.isEnabled = isEnabled
        self.onTap = onTap
    }

    public var content: ElementContent {
        ElementContent(child: wrappedElement)
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        Button.NativeButton.describe { config in
            config.contentView = { $0.contentView }
            config[\.isEnabled] = isEnabled
            config[\.onTap] = onTap
            config[\.minimumTappableSize] = minimumTappableSize
        }
    }

}

extension Button {

    fileprivate final class NativeButton: UIControl {
        internal let contentView = UIView()
        internal var onTap: (() -> Void)? = nil
        internal var minimumTappableSize: CGSize = CGSize(width: 44, height: 44)


        override init(frame: CGRect) {
            super.init(frame: frame)
            contentView.frame = bounds
            contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            contentView.isUserInteractionEnabled = false
            addSubview(contentView)

            addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        }

        public required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private var tappableRect: CGRect {
            bounds
                .insetBy(
                    dx: min(0, bounds.width - minimumTappableSize.width),
                    dy: min(0, bounds.height - minimumTappableSize.height)
                )

        }

        override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
            tappableRect.contains(point)
        }

        override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
            contentView.alpha = 0.2
            return super.beginTracking(touch, with: event)
        }

        override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
            // Mimic UIButtonStyle.system
            if tappableRect.insetBy(dx: -70, dy: -70).contains(touch.location(in: self)) {
                animateAlpha(to: 0.2)
            } else {
                animateAlpha(to: 1)
            }

            return super.continueTracking(touch, with: event)
        }

        override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
            super.endTracking(touch, with: event)
            animateAlpha(to: 1, forcedStartAlpha: 0.2)
        }

        override func cancelTracking(with event: UIEvent?) {
            super.cancelTracking(with: event)
            contentView.alpha = 1
        }

        override var isEnabled: Bool {
            didSet {
                guard oldValue != isEnabled else { return }
                contentView.layer.removeAnimation(forKey: "opacity")
                contentView.alpha = isEnabled ? 1 : 0.2
            }
        }

        private func animateAlpha(to alpha: CGFloat, forcedStartAlpha: CGFloat? = nil) {
            if abs(contentView.alpha - alpha) > 0.0001 {
                let animation = CABasicAnimation(keyPath: "opacity")
                animation.fromValue = forcedStartAlpha ?? contentView.layer.presentation()?.opacity
                animation.toValue = alpha
                animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.default)
                animation.duration = 0.47
                contentView.alpha = alpha
                contentView.layer.add(animation, forKey: "opacity")
            }
        }

        @objc private func handleTap() {
            onTap?()
        }
    }
}
