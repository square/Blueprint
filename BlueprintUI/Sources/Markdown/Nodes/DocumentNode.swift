//
//  Document.swift
//  Down
//
//  Created by John Nguyen on 09.04.19.
//

import Foundation
import libcmark

public class DocumentNode: BaseNode {

    // MARK: - Life cycle

    deinit {
        cmark_node_free(cmarkNode)
    }

    // MARK: - Methods

    /// Accepts the given visitor and return its result.

    @discardableResult
    public func accept<T: Visitor>(_ visitor: T) -> T.Result {
        visitor.visit(document: self)
    }

}

// MARK: - Debug

extension DocumentNode: CustomDebugStringConvertible {

    public var debugDescription: String {
        "Document"
    }

}
