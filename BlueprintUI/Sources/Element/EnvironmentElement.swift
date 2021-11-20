//
//  EnvironmentElement.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 7/2/21.
//

import Foundation


/// Allows creating an `Element` with access to the current `Environment`.
public protocol EnvironmentElement : Element {
    
    /// Return your `Element` body, reading from the constraint and environment as necessary.
    func elementRepresentation(in size : SizeConstraint, with environment : Environment) -> Element
}


extension EnvironmentElement {
    
    public var content: ElementContent {
        ElementContent { constraint, context in
            self.elementRepresentation(in: constraint, with: context.environment)
        }
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        nil
    }
}
