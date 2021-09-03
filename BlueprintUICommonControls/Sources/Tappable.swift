import BlueprintUI
import UIKit


/// Wraps a content element and calls the provided closure when tapped.
public struct Tappable: Element {

    public var wrappedElement: Element
    public var onTap: () -> Void

    public init(onTap: @escaping () -> Void, wrapping element: Element) {
        wrappedElement = element
        self.onTap = onTap
    }

    public var content: ElementContent {
        ElementContent(child: wrappedElement)
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        TappableView.describe { config in
            config[\.onTap] = onTap
        }
    }

}


extension Element {

    /// Wraps the element and calls the provided closure when tapped.
    public func tappable(onTap: @escaping () -> Void) -> Tappable {
        Tappable(onTap: onTap, wrapping: self)
    }
}


fileprivate final class TappableView: UIView {

    var onTap: (() -> Void)? = nil

    override init(frame: CGRect) {
        super.init(frame: frame)

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        addGestureRecognizer(tapRecognizer)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func tapped() {
        onTap?()
    }

}
