//
//  LineBreak.swift
//  Down
//
//  Created by John Nguyen on 09.04.19.
//

import Foundation
import libcmark

public class LineBreakNode: BaseNode {}

// MARK: - Debug

extension LineBreakNode: CustomDebugStringConvertible {

    public var debugDescription: String {
        "Line Break"
    }

}
