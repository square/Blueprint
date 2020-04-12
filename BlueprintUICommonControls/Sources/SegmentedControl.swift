import UIKit
import BlueprintUI


/// Allows users to pick from an array of options.
public struct SegmentedControl: Element {

    public var items: [Item]

    public var selection: Selection = .none

    public var font: UIFont = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.body)
    public var roundingScale: CGFloat = UIScreen.main.scale

    public init(items: [Item] = []) {
        self.items = items
    }

    public mutating func appendItem(title: String, width: Item.Width = .automatic, onSelect: @escaping ()->Void) {
        items.append(Item(title: title, width: width, onSelect: onSelect))
    }

    public var content: ElementContent {
        return ElementContent { constraint in
            self.items.reduce(CGSize.zero, { (current, item) -> CGSize in
                let itemSize = item.measure(font: self.font, in: constraint, roundingScale: self.roundingScale)
                return CGSize(
                    width: itemSize.width + current.width,
                    height: max(itemSize.height, current.height)
                )
            })
        }
    }

    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return SegmentedControlView.describe { config in
            config[\.element] = self
        }
    }

    fileprivate var titleTextAttributes: [NSAttributedString.Key:Any] {
        return [NSAttributedString.Key.font: font]
    }

}

extension SegmentedControl {

    public enum Selection {
        case none
        case index(Int)

        fileprivate var resolvedIndex: Int {
            switch self {
            case .none:
                return UISegmentedControl.noSegment
            case let .index(index):
                return index
            }
        }
    }

    public struct Item {

        public var title: String

        public var width: Width = .automatic

        public var onSelect: () -> Void

        internal func measure(font: UIFont, in constraint: SizeConstraint, roundingScale: CGFloat) -> CGSize {
            return CGSize(
                width: width.requiredWidth(for: title, font: font, in: constraint, roundingScale: roundingScale),
                height: 36.0)
        }

    }

}

extension SegmentedControl.Item {

    public enum Width {
        case automatic
        case specific(CGFloat)

        fileprivate var resolvedWidth: CGFloat {
            switch self {
            case .automatic:
                return 0.0
            case let .specific(width):
                return width
            }
        }

        fileprivate func requiredWidth(
            for title: String,
            font: UIFont,
            in constraint: SizeConstraint,
            roundingScale: CGFloat
        ) -> CGFloat {
            switch self {
            case .automatic:
                let width = (title as NSString)
                    .boundingRect(
                        with: constraint.maximum,
                        options: [.usesLineFragmentOrigin],
                        attributes: [.font: font],
                        context: nil)
                    .size
                    .width
                    .rounded(.up, by: roundingScale)

                return width + 8 // 4pt padding on each side
            case let .specific(width):
                return width
            }
        }
    }

}


fileprivate final class SegmentedControlView: UIView {

    fileprivate var element: SegmentedControl = SegmentedControl() {
        didSet {
            reload()
        }
    }

    private let segmentedControl = UISegmentedControl()

    override init(frame: CGRect) {
        super.init(frame: frame)
        segmentedControl.apportionsSegmentWidthsByContent = true
        addSubview(segmentedControl)

        segmentedControl.addTarget(self, action: #selector(selectionChanged), for: UIControl.Event.valueChanged)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        segmentedControl.frame = bounds
    }

    private func reload() {

        for (offset, item) in element.items.enumerated() {

            if segmentedControl.numberOfSegments <= offset {
                segmentedControl.insertSegment(
                    withTitle: item.title,
                    at: offset,
                    animated: false)
            } else {
                if item.title != segmentedControl.titleForSegment(at: offset) {
                    segmentedControl.setTitle(item.title, forSegmentAt: offset)
                }
            }

            if segmentedControl.widthForSegment(at: offset) != item.width.resolvedWidth {
                segmentedControl.setWidth(
                    item.width.resolvedWidth,
                    forSegmentAt: offset)
            }

        }

        while segmentedControl.numberOfSegments > element.items.count {
            segmentedControl.removeSegment(at: segmentedControl.numberOfSegments-1, animated: false)
        }

        if segmentedControl.selectedSegmentIndex != element.selection.resolvedIndex {
            segmentedControl.selectedSegmentIndex = element.selection.resolvedIndex
        }

        segmentedControl.setTitleTextAttributes(element.titleTextAttributes, for: .normal)
    }

    @objc private func selectionChanged() {
        let item = element.items[segmentedControl.selectedSegmentIndex]
        item.onSelect()
    }

}
