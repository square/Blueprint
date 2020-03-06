@testable import BlueprintUI
import QuartzCore

extension Element {
    /// Build a fully laid out element tree with complete layout attributes
    /// for each element.
    ///
    /// - Parameter frame: The frame to assign to the root element.
    ///
    /// - Returns: A layout result
    func layout(frame: CGRect) -> LayoutResultNode {
        return layout(layoutAttributes: LayoutAttributes(frame: frame), environment: Environment())
    }
}
