//
//  XcodePreviewScratchpad.swift
//  SampleApp
//
//  Created by Kyle Van Essen on 4/16/20.
//  Copyright © 2020 Square. All rights reserved.
//

import BlueprintUI
import BlueprintUICommonControls


struct DiningOptions : ProxyElement {
    
    var options : [String]
    
    var elementRepresentation: Element {
        GeometryReader { size in
            let row = Row { row in
                
                let width = size.width == .unconstrained ? 100 : size.width.maximum
                
                self.options.forEach { option in
                    row.add(child: Item(title: option, width: width))
                }
            }
            
            return ScrollView(wrapping: row) {
                $0.contentSize = .fittingWidth
            }
        }
    }
    
    struct Item : ProxyElement {
        var title : String
        var width : CGFloat
        
        var elementRepresentation: Element {
            ConstrainedSize(
                width: .absolute(width),
                wrapping: Label(text: self.title) {
                    $0.alignment = .center
            })
        }
    }
}

#if DEBUG && canImport(SwiftUI) && !arch(i386)

import SwiftUI


@available(iOS 13.0, *)
struct DiningOptions_Preview : PreviewProvider {
    static var previews: some View {
        ElementPreview(with: .fixed(width: 300, height: 100)) {
            DiningOptions(options : [
                "For Here",
                "To Go",
                "Pickup",
                "Delivery"
            ])
        }
    }
}

//fileprivate struct DemoState {
//    var clicks : Int
//}
//
//@available(iOS 13.0, *)
//struct DemoState_Preview: PreviewProvider {
//    static var previews: some View {
//        ElementPreview(with: .thatFits(padding: 20)) {
//
//            Column {
//                $0.add(child: self.child())
//                $0.add(child: self.child())
//                $0.add(child: self.child())
//                $0.add(child: self.child())
//            }
//
//        }
//    }
//
//    static func child() -> Element {
//        Stateful(initial: DemoState(clicks: 0)) { state in
//            Tappable(
//                onTap: {
//                    state.value.clicks += 1
//                },
//                wrapping: Label(text: "Clicks: \(state.value.clicks)")
//            )
//        }
//    }
//}

#endif
