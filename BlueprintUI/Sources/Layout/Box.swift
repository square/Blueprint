import UIKit


/// A simple element that wraps a child element and adds visual styling including
/// background color.
public struct Box: Element {
    
    public var backgroundColor: UIColor = .clear
    public var cornerStyle: CornerStyle = .square
    public var borderStyle: BorderStyle = .none
    public var shadowStyle: ShadowStyle = .none
    public var clipsContent: Bool = false

    public var wrappedElement: Element?

    public init(
        backgroundColor: UIColor = .clear,
        cornerStyle: CornerStyle = .square,
        wrapping element: Element? = nil
    ) {
        self.backgroundColor = backgroundColor
        self.cornerStyle = cornerStyle
        self.wrappedElement = element
    }
    
    public init(
        wrapping element: Element? = nil,
        configure : (inout Box) -> () = { _ in }
    ) {
        self.wrappedElement = element
        
        configure(&self)
    }

    public var content: ElementContent {
        if let wrappedElement = wrappedElement {
            return ElementContent(child: wrappedElement)
        } else {
            return ElementContent(intrinsicSize: .zero)
        }
    }

    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return BoxView.describe { config in

            config.apply({ (view) in

                if self.backgroundColor != view.backgroundColor {
                    view.backgroundColor = self.backgroundColor
                }

                if self.cornerStyle.radius != view.layer.cornerRadius {
                    view.layer.cornerRadius = self.cornerStyle.radius
                }

                if self.borderStyle.color?.cgColor != view.layer.borderColor {
                    view.layer.borderColor = self.borderStyle.color?.cgColor
                }

                if self.borderStyle.width != view.layer.borderWidth {
                    view.layer.borderWidth = self.borderStyle.width
                }

                if self.shadowStyle.radius != view.layer.shadowRadius {
                    view.layer.shadowRadius = self.shadowStyle.radius
                }

                if self.shadowStyle.offset != view.layer.shadowOffset {
                    view.layer.shadowOffset = self.shadowStyle.offset
                }

                if self.shadowStyle.color?.cgColor != view.layer.shadowColor {
                    view.layer.shadowColor = self.shadowStyle.color?.cgColor
                }

                if self.shadowStyle.opacity != CGFloat(view.layer.shadowOpacity) {
                    view.layer.shadowOpacity = Float(self.shadowStyle.opacity)
                }

                /// `.contentView` is used for clipping, make sure the corner radius
                /// matches.

                if self.clipsContent != view.contentView.clipsToBounds {
                    view.contentView.clipsToBounds = self.clipsContent
                }

                if self.cornerStyle.radius != view.contentView.layer.cornerRadius {
                    view.contentView.layer.cornerRadius = self.cornerStyle.radius
                }

            })


            config.contentView = { view in
                return view.contentView
            }

        }
    }
}

extension Box {

    public enum CornerStyle {
        case square
        case rounded(radius: CGFloat)
    }

    public enum BorderStyle {
        case none
        case solid(color: UIColor, width: CGFloat)
    }

    public enum ShadowStyle {
        case none
        case simple(radius: CGFloat, opacity: CGFloat, offset: CGSize, color: UIColor)
    }

}

extension Box.CornerStyle {

    fileprivate var radius: CGFloat {
        switch self {
        case .square:
            return 0
        case let .rounded(radius: radius):
            return radius
        }
    }

}

extension Box.BorderStyle {
    
    fileprivate var width: CGFloat {
        switch self {
        case .none:
            return 0.0
        case let .solid(_, width):
            return width
        }
    }
    
    fileprivate var color: UIColor? {
        switch self {
        case .none:
            return nil
        case let .solid(color, _):
            return color
        }
    }
    
}

extension Box.ShadowStyle {
    
    fileprivate var radius: CGFloat {
        switch self {
        case .none:
            return 0.0
        case let .simple(radius, _, _, _):
            return radius
        }
    }
    
    fileprivate var opacity: CGFloat {
        switch self {
        case .none:
            return 0.0
        case let .simple(_, opacity, _, _):
            return opacity
        }
    }
    
    fileprivate var offset: CGSize {
        switch self {
        case .none:
            return .zero
        case let .simple(_, _, offset, _):
            return offset
        }
    }
    
    fileprivate var color: UIColor? {
        switch self {
        case .none:
            return nil
        case let .simple(_, _, _, color):
            return color
        }
    }
    
    
}

fileprivate final class BoxView: UIView {
    
    let contentView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.frame = bounds
        addSubview(contentView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = bounds
    }
    
}
