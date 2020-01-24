//
//  EmptyElementTesting.swift
//  SampleApp
//
//  Created by Kyle Van Essen on 1/23/20.
//  Copyright © 2020 Square. All rights reserved.
//

import UIKit
import BlueprintUI
import BlueprintUICommonControls


final class EmptyElementTestingViewController : UIViewController
{
    let blueprintView = BlueprintView()
    
    override func loadView()
    {
        self.view = self.blueprintView
        
        self.blueprintView.element = Column { column in
            column.horizontalAlignment = .fill
            column.verticalUnderflow = .growProportionally
            
            column.add(child: EmptyElement())
        }
    }
}

fileprivate struct EmptyElement : Element
{
    var content: ElementContent {
        return ElementContent(measureFunction: { _ in
            return .zero
        })
    }
    
    func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription?
    {
        ViewDescription(UIView.self) { config in }
    }
}
