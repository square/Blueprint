//
//  Paragraph.swift
//  Down
//
//  Created by John Nguyen on 09.04.19.
//

import Foundation
import libcmark

public class ParagraphNode: BaseNode {}

// MARK: - Debug

extension ParagraphNode: CustomDebugStringConvertible {

    public var debugDescription: String {
        "Paragraph"
    }

}
