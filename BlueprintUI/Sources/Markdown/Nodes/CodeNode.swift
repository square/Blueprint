//
//  Code.swift
//  Down
//
//  Created by John Nguyen on 09.04.19.
//

import Foundation
import libcmark

public class CodeNode: BaseNode {

    // MARK: - Properties

    /// The code content, if present.

    public private(set) lazy var literal: String? = cmarkNode.literal

}

// MARK: - Debug

extension CodeNode: CustomDebugStringConvertible {

    public var debugDescription: String {
        "Code - \(literal ?? "nil")"
    }

}
