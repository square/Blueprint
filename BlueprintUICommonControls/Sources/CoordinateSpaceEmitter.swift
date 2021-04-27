//
//  CoordinateSpaceEmitter.swift
//  BlueprintUICommonControls
//
//  Created by Andrew Watt on 2/4/21.
//

import UIKit
import BlueprintUI

public struct CoordinateSpaceEmitter: Element {
    public typealias CoordinateSpaceEmitted = (UICoordinateSpace) -> Void

    public var wrapped: Element
    public var onCoordinateSpaceEmitted: CoordinateSpaceEmitted

    public init(onCoordinateSpaceEmitted: @escaping CoordinateSpaceEmitted, wrapping wrapped: Element) {
        self.onCoordinateSpaceEmitted = onCoordinateSpaceEmitted
        self.wrapped = wrapped
    }

    public var content: ElementContent {
        ElementContent(child: wrapped)
    }

    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        View.describe { config in
            config[\.onCoordinateSpaceEmitted] = onCoordinateSpaceEmitted
        }
    }
}

extension Element {
    public func emitCoordinateSpace(_ onCoordinateSpaceEmitted: @escaping CoordinateSpaceEmitter.CoordinateSpaceEmitted) -> CoordinateSpaceEmitter {
        CoordinateSpaceEmitter(onCoordinateSpaceEmitted: onCoordinateSpaceEmitted, wrapping: self)
    }
}

extension CoordinateSpaceEmitter {
    class View: UIView {

        var onCoordinateSpaceEmitted: CoordinateSpaceEmitted?

        private var displayLink: CADisplayLink?
        private var previousGlobalFrame: CGRect?

        override init(frame: CGRect) {
            super.init(frame: frame)

            displayLink = CADisplayLink(target: self, selector: #selector(emitCoordinateSpaceIfNeeded))
            displayLink?.add(to: .main, forMode: .common)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        @objc private func emitCoordinateSpaceIfNeeded() {
            guard let window = self.window else { return }

            let globalFrame = convert(bounds, to: window)

            if globalFrame != previousGlobalFrame {
                previousGlobalFrame = globalFrame
                onCoordinateSpaceEmitted?(self)
            }
        }
    }
}
