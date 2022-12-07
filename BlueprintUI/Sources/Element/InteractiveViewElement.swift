//
//  InteractiveViewElement.swift
//
//
//  Created by Kyle Van Essen on 12/2/22.
//

import UIKit


public protocol InteractiveViewElement: Element {

    typealias Content = InteractiveViewElementContent<State, View>

    associatedtype State: InteractiveViewElementContentState
    associatedtype View: UIView

    var viewContent: InteractiveViewElementContent<State, View> { get }

}


public struct InteractiveViewElementContent<State, View: UIView> {

    public var element: (State) -> Element

    public var view: (InteractiveElementViewContext, ViewDescriptionContext) -> ViewDescription

    public init(
        element: @escaping (State) -> Element,
        view: @escaping (InteractiveElementViewContext, ViewDescriptionContext) -> ViewDescription
    ) {
        self.element = element
        self.view = view
    }
}


public protocol InteractiveViewElementContentState {

    static var defaultValue: Self { get }

}


public struct InteractiveElementViewContext {}


extension InteractiveViewElement {

    public var content: ElementContent {
        ElementContent(withInteractiveElement: self)
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        fatalError("TODO")
    }

    var measurementContent: Element {
        viewContent.element(State.defaultValue)
    }
}


// final class InteractiveViewBinding<State:InteractiveViewElementContentState> {
//
//    var value : State
// }

public protocol InteractiveElementView: UIView {

    func setContent(_ content: InteractiveElementViewContent)
}


public struct InteractiveElementViewContent {}
