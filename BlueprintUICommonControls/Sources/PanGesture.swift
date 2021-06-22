//
//  PanGesture.swift
//  BlueprintUICommonControls
//
//  Created by Kyle Bashour on 6/8/21.
//

import BlueprintUI
import UIKit

public struct PanGesture: Element {

    public var onChange: (State) -> Void

    public var isEnabled: Bool = true

    public var wrappedElement: Element?

    public init(
        onChange: @escaping (State) -> Void,
        isEnabled: Bool = true,
        wrappedElement: Element? = nil
    ) {
        self.onChange = onChange
        self.isEnabled = isEnabled
        self.wrappedElement = wrappedElement

    }

    public var content: ElementContent {
        if let wrappedElement = wrappedElement {
            return ElementContent(child: wrappedElement)
        } else {
            return ElementContent(intrinsicSize: .zero)
        }
    }

    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        PanGestureView.describe { config in
            config[\.panGesture.isEnabled] = isEnabled
            config[\.onChange] = onChange
        }
    }
}

extension Element {
    public func panGesture(onChange: @escaping (PanGesture.State) -> Void) -> Element {
        PanGesture(onChange: onChange, wrappedElement: self)
    }
}

extension PanGesture {
    public struct Movement {
        var containerBounds: CGRect
        var location: CGPoint
        var translation: CGPoint
        var velocity: CGPoint
    }

    public enum State {
        case ended(Movement)
        case cancelled(Movement)
        case moving(Movement)
    }
}

private final class PanGestureView: UIView {

    let panGesture = UIPanGestureRecognizer()

    var onChange: ((PanGesture.State) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)

        addGestureRecognizer(panGesture)
        panGesture.addTarget(self, action: #selector(panned))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func panned(panGesture: UIPanGestureRecognizer) {

        let movement = PanGesture.Movement(
            containerBounds: bounds,
            location: panGesture.location(in: self),
            translation: panGesture.translation(in: self),
            velocity: panGesture.velocity(in: self)
        )

        switch panGesture.state {
        case .began, .changed:
            onChange?(.moving(movement))
        case .ended:
            onChange?(.ended(movement))
        case .cancelled:
            onChange?(.cancelled(movement))
        default:
            break
        }
    }
}
