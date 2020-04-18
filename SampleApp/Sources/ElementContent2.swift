import UIKit

import BlueprintUI

/// Represents the content of an element.
public struct ElementContent: Measurable {

    public func measure(in constraint: SizeConstraint) -> CGSize {
        fatalError()
    }
}


extension ElementContent {

    public struct Builder<LayoutType: Layout> {

        /// The layout object that is ultimately responsible for measuring
        /// and layout tasks.
        public var layout: LayoutType

        /// Child elements.
        fileprivate var children: [Child] = []

        init(layout: LayoutType) {
            self.layout = layout
        }

    }


}


extension ElementContent.Builder {

    fileprivate struct Child: Measurable {

        var traits: LayoutType.Traits
        var key: AnyHashable?
        var content: ElementContent
        var element: Element

        func measure(in constraint: SizeConstraint) -> CGSize {
            return content.measure(in: constraint)
        }

    }
}


#if DEBUG && canImport(SwiftUI) && !arch(i386)

import SwiftUI

@available(iOS 13.0, *)
struct ElementContent_Preview: PreviewProvider {
    static var previews: some View {
        Text("Hello, World!")
    }
}

#endif
