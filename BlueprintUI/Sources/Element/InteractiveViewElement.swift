//
//  InteractiveViewElement.swift
//
//
//  Created by Kyle Van Essen on 12/2/22.
//

import UIKit


public protocol InteractiveViewElement: Element {

    typealias Content = InteractiveViewElementContent<State, View>

    associatedtype State
    associatedtype View: UIView

    var viewContent: InteractiveViewElementContent<State, View> { get }

}


public struct InteractiveViewElementContent<State, View: UIView> {

    public var element: (State) -> Element
    public var measuring: State
    public var view: (InteractiveElementViewContext<State>, ViewDescriptionContext) -> ViewDescription

    public init(
        element: @escaping (State) -> Element,
        measuring: () -> State,
        view: @escaping (InteractiveElementViewContext<State>, ViewDescriptionContext) -> ViewDescription
    ) {
        self.element = element
        self.measuring = measuring()
        self.view = view
    }
}


public struct InteractiveElementViewContext<State> {

    public let binding: InteractiveViewBinding<State>
}


extension InteractiveViewElement {

    public var content: ElementContent {
        ElementContent(withInteractiveElement: self)
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        let binding = context.environment[AnyInteractiveViewBinding.Key.self] as! InteractiveViewBinding<State>

        return viewContent.view(InteractiveElementViewContext<State>(binding: binding), context)
    }

    var measurementContent: Element {
        viewContent.element(viewContent.measuring)
    }
}


public final class InteractiveViewBinding<State>: AnyInteractiveViewBinding {

    var onValueDidChange: ((State) -> Void)? = nil

    public var value: State {
        didSet {}
    }

    public init(_ value: State) {
        self.value = value
    }

    public func modify(_ modify: (inout State) -> Void) {
        var copy = value
        modify(&copy)
        value = copy
    }
}


public class AnyInteractiveViewBinding {


    enum Key: EnvironmentKey {

        static var defaultValue: AnyInteractiveViewBinding? {
            nil
        }

        static func isEquivalent(_ lhs: AnyInteractiveViewBinding?, _ rhs: AnyInteractiveViewBinding?) -> Bool {
            lhs === rhs
        }
    }
}


public struct InteractiveElementViewContent {}


public protocol InteractiveElementView<State>: UIView {

    associatedtype State

    var binding: InteractiveViewBinding<State>? { get }

    func bind(to: InteractiveViewBinding<State>)
}


extension BlueprintView {

    public static func makeInteractive<State>(
    ) -> some InteractiveElementView<State> {
        BindableBlueprintView<State>()
    }
}

fileprivate final class BindableBlueprintView<State>: BlueprintView, InteractiveElementView {

    // MARK: InteractiveElementView

    public var binding: InteractiveViewBinding<State>?

    public func bind(to: InteractiveViewBinding<State>) {
        fatalError("TODO")
    }

}
