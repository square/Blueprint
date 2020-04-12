import BlueprintUI
import UIKit


/// Displays an image within an element hierarchy.
public struct Image: Element {

    /// The image to be displayed
    public var image: UIImage?

    /// The tint color.
    public var tintColor: UIColor? = nil

    /// The content mode determines the layout of the image when its size does
    /// not precisely match the size that the element is assigned.
    public var contentMode: ContentMode = .aspectFill

    /// Initializes an image element with the given `UIImage` instance.
    public init(image: UIImage?) {
        self.image = image
    }

    public var content: ElementContent {
        ElementContent {
            Measurer(
                contentMode: self.contentMode,
                imageSize: self.image?.size
            ).measure(in: $0)
        }
    }

    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return UIImageView.describe { config in
            config[\.image] = image
            config[\.contentMode] = contentMode.uiViewContentMode
            config[\.layer.minificationFilter] = .trilinear
            config[\.tintColor] = tintColor
        }
    }

}

extension Image {

    /// The content mode determines the layout of the image when its size does
    /// not precisely match the size that the element is assigned.
    public enum ContentMode {

        /// The image is not scaled, and is simply centered within the `Image`
        /// element.
        case center

        /// The image is stretched to fill the `Image` element, causing the image
        /// to become distorted if its aspect ratio is different than that of the
        /// containing element.
        case stretch

        /// The image is scaled to touch the edges of the `Image` element while
        /// maintaining the image's aspect ratio. If the aspect ratio of the
        /// image is different than that of the element, the image will be
        /// letterboxed or pillarboxed as needed to ensure that the entire
        /// image is visible within the element.
        case aspectFit

        /// The image is scaled to fill the entire `Image` element. If the aspect
        /// ratio of the image is different than that of the element, the image
        /// will be cropped to match the element's aspect ratio.
        case aspectFill

        fileprivate var uiViewContentMode: UIView.ContentMode {
            switch self {
            case .center: return .center
            case .stretch: return .scaleToFill
            case .aspectFit: return .scaleAspectFit
            case .aspectFill: return .scaleAspectFill
            }
        }
    }

}


extension CGSize {

    fileprivate var aspectRatio: CGFloat {
        if height > 0.0 {
            return width/height
        } else {
            return 0.0
        }
    }
}

extension Image {

    fileprivate struct Measurer {

        var contentMode: ContentMode
        var imageSize: CGSize?

        func measure(in constraint: SizeConstraint) -> CGSize {
            guard let imageSize = imageSize else { return .zero }

            enum Mode {
                case fitWidth(CGFloat)
                case fitHeight(CGFloat)
                case useImageSize
            }

            let mode: Mode

            switch contentMode {
            case .center, .stretch:
                mode = .useImageSize
            case .aspectFit, .aspectFill:
                if case .atMost(let width) = constraint.width, case .atMost(let height) = constraint.height {
                    if CGSize(width: width, height: height).aspectRatio > imageSize.aspectRatio {
                        mode = .fitWidth(width)
                    } else {
                        mode = .fitHeight(height)
                    }
                } else if case .atMost(let width) = constraint.width {
                    mode = .fitWidth(width)
                } else if case .atMost(let height) = constraint.height {
                    mode = .fitHeight(height)
                } else {
                    mode = .useImageSize
                }
            }

            switch mode {
            case .fitWidth(let width):
                return CGSize(
                    width: width,
                    height: width / imageSize.aspectRatio)
            case .fitHeight(let height):
                return CGSize(
                    width: height * imageSize.aspectRatio,
                    height: height)
            case .useImageSize:
                return imageSize
            }


        }

    }

}
