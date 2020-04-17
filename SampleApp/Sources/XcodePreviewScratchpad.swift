//
//  XcodePreviewScratchpad.swift
//  SampleApp
//
//  Created by Kyle Van Essen on 4/16/20.
//  Copyright © 2020 Square. All rights reserved.
//

import BlueprintUI
import BlueprintUICommonControls


#if DEBUG && canImport(SwiftUI) && !arch(i386)

import SwiftUI

fileprivate struct DemoState {
    var clicks : Int
}

@available(iOS 13.0, *)
struct DemoState_Preview: PreviewProvider {
    static var previews: some View {
        ElementPreview(with: .thatFits(padding: 20)) {
            
            Column {
                $0.add(child: self.child())
                $0.add(child: self.child())
                $0.add(child: self.child())
                $0.add(child: self.child())
            }
            
        }
    }
    
    static func child() -> Element {
        Stateful(initial: DemoState(clicks: 0)) { state in
            Tappable(
                onTap: {
                    state.value.clicks += 1
                },
                wrapping: Label(text: "Clicks: \(state.value.clicks)")
            )
        }
    }
}

#endif
