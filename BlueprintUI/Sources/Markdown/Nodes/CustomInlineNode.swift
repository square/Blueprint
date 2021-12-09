//
//  CustomInline.swift
//  Down
//
//  Created by John Nguyen on 09.04.19.
//

import Foundation
import libcmark

public class CustomInlineNode: BaseNode {

    // MARK: - Properties

    /// The custom content, if present.

    public private(set) lazy var literal: String? = cmarkNode.literal
}

// MARK: - Debug

extension CustomInlineNode: CustomDebugStringConvertible {

    public var debugDescription: String {
        "Custom Inline - \(literal ?? "nil")"
    }

}
