//
//  XcodePreviewDemo.swift
//  SampleApp
//
//  Created by Kyle Van Essen on 4/14/20.
//  Copyright © 2020 Square. All rights reserved.
//

@testable import BlueprintUI
@testable import BlueprintUICommonControls


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
    
    static var attributedText : NSAttributedString {
        //return NSAttributedString()
        
        let parsed = try? HTMLParser(
            html: "The <b>quick</b> brown fox jumps over the <i>lazy dog</i>"
        ).parse()
        
        let format = HTML.Format(
            rootAttributes: .init(pointSize: 18.0, weight: .regular),
            tagFormats: [
                [HTML.Format.TagName(name: "b", synonyms: [])]: HTML.Tag.Format([.font : .init(UIFont.systemFont(ofSize: 20.0, weight: .bold))])
            ]
        )
        
        return parsed?.toAttributed(with: format) ?? NSAttributedString()
    }
    
    static var previews: some View {
        ElementPreview(with: .fixed(width: 300, height: 200)) {
            AttributedLabel(attributedText: Self.attributedText)
        }
    }
}

#endif
