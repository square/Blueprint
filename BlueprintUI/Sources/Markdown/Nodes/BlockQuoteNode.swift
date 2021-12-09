//
//  BlockQuote.swift
//  Down
//
//  Created by John Nguyen on 09.04.19.
//

import Foundation
import libcmark

public class BlockQuoteNode: BaseNode {}

// MARK: - Debug

extension BlockQuoteNode: CustomDebugStringConvertible {

    public var debugDescription: String {
        "Block Quote"
    }

}
