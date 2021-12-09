//
//  SoftBreak.swift
//  Down
//
//  Created by John Nguyen on 09.04.19.
//

import Foundation
import libcmark

public class SoftBreakNode: BaseNode {}

// MARK: - Debug

extension SoftBreakNode: CustomDebugStringConvertible {

    public var debugDescription: String {
        "Soft Break"
    }

}
