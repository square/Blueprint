import UIKit
import BlueprintUI


/// A simple element that wraps a child element and adds visual styling including
/// background color.
public struct Box: Element {
    
    public var backgroundColor: UIColor
    public var cornerStyle: CornerStyle
    public var borderStyle: BorderStyle
    public var shadowStyle: ShadowStyle
    public var clipsContent: Bool

    public var wrappedElement: Element?

    public init(
        backgroundColor: UIColor = .clear,
        cornerStyle: CornerStyle = .square,
        borderStyle: BorderStyle = .none,
        shadowStyle: ShadowStyle = .none,
        clipsContent: Bool = false,
        wrapping element: Element? = nil
    ) {
        self.backgroundColor = backgroundColor
        self.cornerStyle = cornerStyle
        self.borderStyle = borderStyle
        self.shadowStyle = shadowStyle
        self.clipsContent = clipsContent
        
        self.wrappedElement = element
    }

    public var content: ElementContent {
        if let wrappedElement = wrappedElement {
            return ElementContent(child: wrappedElement)
        } else {
            return ElementContent(intrinsicSize: .zero)
        }
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        return BoxView.describe { config in

            config.apply({ (view) in

                if self.backgroundColor != view.backgroundColor {
                    view.backgroundColor = self.backgroundColor
                }
                
                if self.cornerStyle.cornerMask != view.layer.maskedCorners {
                    view.layer.maskedCorners = self.cornerStyle.cornerMask
                }

                if self.cornerStyle.radius(for: context.bounds) != view.layer.cornerRadius {
                    view.layer.cornerRadius = self.cornerStyle.radius(for: context.bounds)
                }

                if self.borderStyle.color?.cgColor != view.layer.borderColor {
                    view.layer.borderColor = self.borderStyle.color?.cgColor
                }

                if self.borderStyle.width != view.layer.borderWidth {
                    view.layer.borderWidth = self.borderStyle.width
                }

                if self.cornerStyle.shadowRoundedCorners != view.shadowRoundCorners {
                    view.shadowRoundCorners = self.cornerStyle.shadowRoundedCorners
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

                if self.cornerStyle.radius(for: context.bounds) != view.contentView.layer.cornerRadius {
                    view.contentView.layer.cornerRadius = self.cornerStyle.radius(for: context.bounds)
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
        case capsule
        case rounded(radius: CGFloat, corners: Corners = .all)
        
        public struct Corners: OptionSet {
            public let rawValue: UInt8

            public init(rawValue: UInt8) {
                self.rawValue = rawValue
            }

            public static let topLeft = Corners(rawValue: 1)
            public static let topRight = Corners(rawValue: 1 << 1)
            public static let bottomLeft = Corners(rawValue: 1 << 2)
            public static let bottomRight = Corners(rawValue: 1 << 3)

            public static var all: Corners = [.topLeft, .topRight, .bottomLeft, .bottomRight]
            public static var top: Corners = [.topRight, .topLeft]
            public static var left: Corners = [.topLeft, .bottomLeft]
            public static var bottom: Corners = [.bottomLeft, .bottomRight]
            public static var right: Corners = [.topRight, .bottomRight]
            
            var toCACornerMask: CACornerMask {
                var mask: CACornerMask = []
                if self.contains(.topLeft) {
                    mask.update(with: .layerMinXMinYCorner)
                }
                
                if self.contains(.topRight) {
                    mask.update(with: .layerMaxXMinYCorner)
                }
                
                if self.contains(.bottomLeft) {
                    mask.update(with: .layerMinXMaxYCorner)
                }
                
                if self.contains(.bottomRight) {
                    mask.update(with: .layerMaxXMaxYCorner)
                }
                return mask
            }
            
            var toUIRectCorner: UIRectCorner {
                var rectCorner: UIRectCorner = []
                if self.contains(.topLeft) {
                    rectCorner.update(with: .topLeft)
                }
                
                if self.contains(.topRight) {
                    rectCorner.update(with: .topRight)
                }
                
                if self.contains(.bottomLeft) {
                    rectCorner.update(with: .bottomLeft)
                }
                
                if self.contains(.bottomRight) {
                    rectCorner.update(with: .bottomRight)
                }
                return rectCorner
            }
        }
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

public extension Element {
    
    /// Wraps the element in a box to provide basic styling.
    func box(
        background: UIColor = .clear,
        corners: Box.CornerStyle = .square,
        borders: Box.BorderStyle = .none,
        shadow: Box.ShadowStyle = .none,
        clipsContent: Bool = false
    ) -> Box
    {
        Box(
            backgroundColor: background,
            cornerStyle: corners,
            borderStyle: borders,
            shadowStyle: shadow,
            clipsContent: clipsContent,
            wrapping: self
        )
    }
}

extension Box.CornerStyle {

    fileprivate func radius(for bounds: CGRect) -> CGFloat {
        switch self {
        case .square:
            return 0
        case .capsule:
            return min(bounds.width, bounds.height) / 2
        case let .rounded(radius: radius, _):
            let maximumRadius = min(bounds.width, bounds.height) / 2
            return min(maximumRadius, radius)
        }
    }

    fileprivate var cornerMask: CACornerMask {
        switch self {
        case .square, .capsule:
            return Corners.all.toCACornerMask
        case let .rounded(_, corners):
            return corners.toCACornerMask
        }
    }
    
    fileprivate var shadowRoundedCorners: UIRectCorner {
        switch self {
        case .square, .capsule:
            return Corners.all.toUIRectCorner
        case let .rounded(_, corners):
            return corners.toUIRectCorner
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
    
    var shadowRoundCorners: UIRectCorner = .allCorners
    
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

        if layer.shadowColor != nil {
            let cornerRadii = CGSize(
                width: layer.cornerRadius,
                height: layer.cornerRadius
            )
            layer.shadowPath = UIBezierPath(
                roundedRect: bounds,
                byRoundingCorners: shadowRoundCorners,
                cornerRadii: cornerRadii
            ).cgPath
        }
    }
    
}
