//
//  ThematicBreak.swift
//  Down
//
//  Created by John Nguyen on 09.04.19.
//

import Foundation
import libcmark

public class ThematicBreakNode: BaseNode {}

// MARK: - Debug

extension ThematicBreakNode: CustomDebugStringConvertible {

    public var debugDescription: String {
        "Thematic Break"
    }

}
