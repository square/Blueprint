import BlueprintUI
import BlueprintUICommonControls


struct TestElement: ProxyElement {
    var elementRepresentation: Element {
        Column {
            $0.verticalUnderflow = .justifyToStart

            for index in 1...12 {
                $0.add(child: Label(text: "Hello, World!") {
                    $0.font = .boldSystemFont(ofSize: 10.0 + CGFloat(index * 4))
                    $0.color = .init(
                        red: CGFloat.random(in: 0...1),
                        green: CGFloat.random(in: 0...1),
                        blue: CGFloat.random(in: 0...1),
                        alpha: 1.0
                    )
                })
            }
        }
    }
}

#if DEBUG && canImport(SwiftUI) && !arch(i386)

import SwiftUI

@available(iOS 13.0, *)
struct TestingView_Preview: PreviewProvider {
    static var previews: some View {
        ElementPreview(with: .thatFits(padding: 5)) {
            TestElement()
        }
    }
}

#endif
