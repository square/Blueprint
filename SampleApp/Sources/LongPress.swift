import BlueprintUI
import BlueprintUICommonControls
import Foundation
import UIKit

public struct LongPress: Element {

    public var wrappedElement: Element
    public var onLongPress: () -> Void

    public init(onLongPress: @escaping () -> Void, wrapping element: Element) {
        wrappedElement = element
        self.onLongPress = onLongPress
    }

    public var content: ElementContent {
        ElementContent(child: wrappedElement)
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        LongPressableView.describe { config in
            config[\.onLongPress] = onLongPress
        }
    }
}

extension Element {

    /// Wraps the element and calls the provided closure when tapped.
    func onLongPress(_ callback: @escaping () -> Void) -> LongPress {
        LongPress(onLongPress: callback, wrapping: self)
    }
}

// MARK: LongPressableView

private final class LongPressableView: UIView, UIGestureRecognizerDelegate {

    var onLongPress: (() -> Void)? = nil
    let longPressRecognizer: UILongPressGestureRecognizer
    private static let defaultPressDuration: TimeInterval = 0.5
    private static let adjustedPressDuration: TimeInterval = 3.0

    override init(frame: CGRect) {
        let longPressRecognizer = UILongPressGestureRecognizer()
        self.longPressRecognizer = longPressRecognizer

        super.init(frame: frame)

        longPressRecognizer.addTarget(self, action: #selector(longPressed(_:)))
        longPressRecognizer.delegate = self
        addGestureRecognizer(longPressRecognizer)

        updateView()
    }

    func updateView() {
        longPressRecognizer.minimumPressDuration = UILargeContentViewerInteraction.isEnabled ? Self.adjustedPressDuration : Self.defaultPressDuration
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        (gestureRecognizer == longPressRecognizer) && (otherGestureRecognizer == ancestorLargeContentViewerInteraction?.gestureRecognizerForExclusionRelationship)
    }

    var ancestorLargeContentViewerInteraction: UILargeContentViewerInteraction? {
        sequence(first: self, next: { $0.superview })
            .dropFirst()
            .lazy
            .compactMap { $0 as? Accessibility.LargeContentViewerInteractionContainerViewable }
            .first?
            .largeContentViewerInteraction
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func longPressed(_ sender: UILongPressGestureRecognizer) {
        // This function is called multiple times during the lifecycle of a single long-press,
        // so we only listen for the "begin" state to avoid calling the onLongPress callback too many times
        guard sender.state == .began else { return }

        onLongPress?()
    }
}

