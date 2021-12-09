//
//  Strong.swift
//  Down
//
//  Created by John Nguyen on 09.04.19.
//

import Foundation
import libcmark

public class StrongNode: BaseNode {}

// MARK: - Debug

extension StrongNode: CustomDebugStringConvertible {

    public var debugDescription: String {
        "Strong"
    }

}
