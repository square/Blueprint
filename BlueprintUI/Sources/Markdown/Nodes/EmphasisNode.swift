//
//  Emphasis.swift
//  Down
//
//  Created by John Nguyen on 09.04.19.
//

import Foundation
import libcmark

public class EmphasisNode: BaseNode {}

// MARK: - Debug

extension EmphasisNode: CustomDebugStringConvertible {

    public var debugDescription: String {
        "Emphasis"
    }

}
