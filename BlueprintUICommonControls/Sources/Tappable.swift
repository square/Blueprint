import BlueprintUI
import UIKit


/// Wraps a content element and calls the provided closure when tapped.
public struct Tappable: Element {

    public var wrappedElement: Element
    public var onTap: () -> Void

    public init(onTap: @escaping () -> Void, wrapping element: Element) {
        self.wrappedElement = element
        self.onTap = onTap
    }

    public var content: ElementContent {
        wrappedElement.content
    }

    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return TappableView.describe { config in
            config[\.onTap] = onTap
        }
    }

}


public extension Element {
    
    /// Wraps the element and calls the provided closure when tapped.
    func tappable(onTap: @escaping () -> Void) -> Tappable {
        Tappable(onTap: onTap, wrapping: self)
    }
}


fileprivate final class TappableView: UIView {

    var onTap: (()->Void)? = nil

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
