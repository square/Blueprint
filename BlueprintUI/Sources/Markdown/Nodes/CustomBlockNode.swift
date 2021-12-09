//
//  CustomBlock.swift
//  Down
//
//  Created by John Nguyen on 09.04.19.
//

import Foundation
import libcmark

public class CustomBlockNode: BaseNode {

    // MARK: - Properfies

    /// The custom content, if present.

    public private(set) lazy var literal: String? = cmarkNode.literal

}

// MARK: - Debug

extension CustomBlockNode: CustomDebugStringConvertible {

    public var debugDescription: String {
        "Custom Block - \(literal ?? "nil")"
    }

}
