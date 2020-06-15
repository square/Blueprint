//
//  UpdateTransition.swift
//  BlueprintUI
//
//  Created by Kyle Bashour on 6/15/20.
//

import Foundation

public struct UpdateTransition {

    private var _perform: (UIView, @escaping () -> Void) -> Void

    public init(perform: @escaping (UIView, @escaping () -> Void) -> Void) {
        self._perform = perform
    }

    func perform(in view: UIView, animations: @escaping () -> Void) {
        _perform(view, animations)
    }
}
