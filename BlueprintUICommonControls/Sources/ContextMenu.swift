import BlueprintUI
import UIKit


public struct ContextMenu: Element {

    public var wrappedElement: Element

    public init(wrapping element: Element) {
        self.wrappedElement = element
    }

    public var content: ElementContent {
        return ElementContent(child: wrappedElement)
    }

    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        if #available(iOS 13.4, *) {
            return ContextMenuView.describe { config in
            }
        } else {
            return nil
        }
    }


}


@available(iOS 13.4, *)
fileprivate final class ContextMenuView: UIView, UIContextMenuInteractionDelegate {

    override init(frame: CGRect) {
        super.init(frame: frame)

        isUserInteractionEnabled = true

        let interaction = UIContextMenuInteraction(delegate: self)
        addInteraction(interaction)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, previewForDismissingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard let view = interaction.view else { return nil }
        return UITargetedPreview(view: view)
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(
            identifier: nil,
            previewProvider: {
                PreviewViewController(element: Label(text: "HI!"))
            },
            actionProvider: { suggestedActions in
                return UIMenu(
                    title: "Title",
                    image: nil,
                    identifier: nil,
                    options: [],
                    children: [
                        UIAction(
                            title: "Hello",
                            image: nil,
                            identifier: nil,
                            discoverabilityTitle: nil,
                            attributes: [],
                            state: .off,
                            handler: { action in
                                print("hello")
                            }
                        ),
                        UIAction(
                            title: "World",
                            image: nil,
                            identifier: nil,
                            discoverabilityTitle: nil,
                            attributes: [],
                            state: .off,
                            handler: { action in
                                print("world")
                            }
                        )
                    ]
                )
            }
        )
    }

    private class PreviewViewController: UIViewController {

        let blueprintView: BlueprintView

        init(element: Element) {
            blueprintView = BlueprintView(element: element)
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func loadView() {
            view = blueprintView
        }

    }

}
