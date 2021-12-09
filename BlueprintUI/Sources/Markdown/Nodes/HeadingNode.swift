//
//  Heading.swift
//  Down
//
//  Created by John Nguyen on 09.04.19.
//

import Foundation
import libcmark

public class HeadingNode: BaseNode {

    // MARK: - Properties

    /// The level of the heading, a value between 1 and 6.

    public private(set) lazy var headingLevel: Int = cmarkNode.headingLevel
}

// MARK: - Debug

extension HeadingNode: CustomDebugStringConvertible {

    public var debugDescription: String {
        "Heading - L\(headingLevel)"
    }

}
