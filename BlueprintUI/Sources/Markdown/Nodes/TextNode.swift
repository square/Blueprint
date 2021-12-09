//
//  Text.swift
//  Down
//
//  Created by John Nguyen on 09.04.19.
//

import Foundation
import libcmark

public class TextNode: BaseNode {

    // MARK: - Properties

    /// The text content, if present.

    public private(set) lazy var literal: String? = cmarkNode.literal

}

// MARK: - Debug

extension TextNode: CustomDebugStringConvertible {

    public var debugDescription: String {
        "Text - \(literal ?? "nil")"
    }

}
