import Foundation
import libcmark

public struct Markdown {
    public enum MarkdownError: Error {
        case failedToParseDocument
    }

    public let document: DocumentNode

    public init(string: String) throws {
        var node: CMarkNode?

        string.withCString { cString in
            node = cmark_parse_document(cString, Int(strlen(cString)), 0)
        }

        guard let node = node else {
            throw MarkdownError.failedToParseDocument
        }

        document = DocumentNode(cmarkNode: node)
    }

    public func render<V: Visitor>(using visitor: V) -> V.Result {
        visitor.visit(document: document)
    }
}
