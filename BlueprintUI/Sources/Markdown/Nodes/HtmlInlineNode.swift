//
//  HtmlInline.swift
//  Down
//
//  Created by John Nguyen on 09.04.19.
//

import Foundation
import libcmark

public class HtmlInlineNode: BaseNode {

    // MARK: - Properties

    /// The html tag, if present.

    public private(set) lazy var literal: String? = cmarkNode.literal

}

// MARK: - Debug

extension HtmlInlineNode: CustomDebugStringConvertible {

    public var debugDescription: String {
        "Html Inline - \(literal ?? "nil")"
    }

}
