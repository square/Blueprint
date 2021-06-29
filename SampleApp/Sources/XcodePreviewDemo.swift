//
//  XcodePreviewDemo.swift
//  SampleApp
//
//  Created by Kyle Van Essen on 4/14/20.
//  Copyright © 2020 Square. All rights reserved.
//

import BlueprintUI
import BlueprintUICommonControls


struct TestElement : ProxyElement {
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
        ElementPreview(with: .fixed(width: 300, height: 500)) {
            MarkdownText(
                """
                ### Here's to the crazy ones.
                
                The **misfits**. The _rebels_. The troublemakers. The round pegs in the square holes. The ones who see things differently. They're not fond of rules. And they have no respect for the status quo. You can quote them, disagree with them, glorify or vilify them. About the only thing you can't do is ignore them. Because they change things. They push the human race forward. And while some may see them as the crazy ones, we see genius. Because the people who are crazy enough to think they can change the world, are the ones who do.
                """
            )
        }
    }
}

#endif
