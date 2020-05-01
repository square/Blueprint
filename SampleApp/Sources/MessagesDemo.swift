//
//  MessagesDemo.swift
//  SampleApp
//
//  Created by Kyle Van Essen on 4/28/20.
//  Copyright © 2020 Square. All rights reserved.
//

import UIKit
import BlueprintUI
import BlueprintUICommonControls


import SwiftUI

@available(iOS 13.0, *)
struct MessagesDemo_Preview : PreviewProvider {
    static var previews: some View {
        ElementPreview(with: .device(.iPhoneX)) {
            MessagesView()
        }
    }
}

struct MessagesView : ProxyElement {
    var elementRepresentation: Element {
        
        let messages = Inset(
            uniformInset: 15.0,
            wrapping: Column {
                $0.horizontalAlignment = .fill
                $0.minimumVerticalSpacing = 20.0
                
                for message in Message.messages {
                    $0.add(
                        growPriority: 0.0,
                        shrinkPriority: 0.0,
                        child: Aligned(
                            horizontally: .trailing,
                            wrapping: ConstrainedSize(
                                width: .atMost(350),
                                wrapping: Message(content: message)
                            )
                        )
                    )
                }
            }
        )
        
        var scrollView = ScrollView(wrapping: messages)
        scrollView.keyboardDismissMode = .interactive
        scrollView.contentSize = .fittingHeight
        
        return InputAccessoryScreen(
            wrapping: scrollView,
            inputAccessory: InputAccessory(style: .keyboard) {
                MessageBar()
            }
        )
    }
    
    struct MessageBar : ProxyElement {
        var elementRepresentation: Element {
            Box(
                backgroundColor: .lightGray,
                wrapping: Inset(
                    uniformInset: 15.0,
                    wrapping: Row {
                        $0.verticalAlignment = .fill
                        $0.add(growPriority: 1.0, shrinkPriority: 1.0, child: BlueprintUICommonControls.TextField(text: "My Message!"))
                    }
                )
            )
        }
    }
    
    struct Message : ProxyElement {
        var content : String
        
        var elementRepresentation: Element {
            Box(
                backgroundColor: .darkGray,
                cornerStyle: .rounded(radius: 20.0),
                wrapping: Inset(
                    uniformInset: 15.0,
                    wrapping: Label(text: content) {
                        $0.font = .systemFont(ofSize: 16.0, weight: .regular)
                        $0.color = .white
                    }
                )
            )
        }
        
        static var messages : [String] = [
            "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
            
            "Duis sagittis posuere tellus at consequat. Nullam laoreet eros non metus sollicitudin, vel porttitor ipsum placerat. Vestibulum sed venenatis magna.",
            
            "Integer laoreet mollis mauris, non venenatis erat pharetra nec. Cras vitae velit sed tellus tincidunt sollicitudin. Vestibulum feugiat nisl sit amet pharetra rutrum.",
            
            "Mauris eu elit et sem condimentum sagittis vitae a est. Nam a odio quis ante eleifend varius. Interdum et malesuada fames ac ante ipsum primis in faucibus. Duis hendrerit lacinia dui a dignissim. Curabitur elit mi, pretium nec dui sit amet, sodales interdum turpis.",
            
            "Curabitur elementum ligula nec justo laoreet maximus. Nunc efficitur augue lorem, a auctor arcu faucibus eu. Sed ac nisi et dui pretium fermentum. Proin ut blandit arcu. Cras placerat vel elit tincidunt cursus.",
            
            "Donec pulvinar lorem quam.",
            
            "Donec lobortis rhoncus scelerisque. Nam ultrices consectetur condimentum. Nullam eget nunc nec libero tristique faucibus quis sit amet ex.",
            
            "Praesent semper neque ut est pretium maximus.",
            
            "Ut luctus arcu tellus, sit amet suscipit leo rutrum a. Cras ullamcorper malesuada ligula at eleifend. Ut non odio felis. Duis sagittis mattis libero vel interdum."
        ]
    }
}
