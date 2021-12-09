//
//  Vistor.swift
//  Down
//
//  Created by John Nguyen on 07.04.19.
//

import Foundation

public protocol VisitorResult {
    static func + (_ lhs: Self, _ rhs: Self) -> Self
    static func empty() -> Self
}

/// Visitor describes a type that is able to traverse the abstract syntax tree. It visits
/// each node of the tree and produces some result for that node. A visitor is "accepted" by
/// the root node (of type `Document`), which will start the traversal by first invoking
/// `visit(document:)`.

public protocol Visitor {

    associatedtype Result

    func visit(document node: DocumentNode) -> Result
    func visit(blockQuote node: BlockQuoteNode) -> Result
    func visit(list node: ListNode) -> Result
    func visit(item node: ItemNode) -> Result
    func visit(codeBlock node: CodeBlock) -> Result
    func visit(htmlBlock node: HtmlBlockNode) -> Result
    func visit(customBlock node: CustomBlockNode) -> Result
    func visit(paragraph node: ParagraphNode) -> Result
    func visit(heading node: HeadingNode) -> Result
    func visit(thematicBreak node: ThematicBreakNode) -> Result
    func visit(text node: TextNode) -> Result
    func visit(softBreak node: SoftBreakNode) -> Result
    func visit(lineBreak node: LineBreakNode) -> Result
    func visit(code node: CodeNode) -> Result
    func visit(htmlInline node: HtmlInlineNode) -> Result
    func visit(customInline node: CustomInlineNode) -> Result
    func visit(emphasis node: EmphasisNode) -> Result
    func visit(strong node: StrongNode) -> Result
    func visit(link node: LinkNode) -> Result
    func visit(image node: ImageNode) -> Result
    func visitChildren(of node: MarkdownNode) -> [Result]

}

extension Visitor {

    public func visitChildren(of node: MarkdownNode) -> [Result] {
        node.childSequence.compactMap { child in
            switch child {
            case let child as DocumentNode: return visit(document: child)
            case let child as BlockQuoteNode: return visit(blockQuote: child)
            case let child as ListNode: return visit(list: child)
            case let child as ItemNode: return visit(item: child)
            case let child as CodeBlock: return visit(codeBlock: child)
            case let child as HtmlBlockNode: return visit(htmlBlock: child)
            case let child as CustomBlockNode: return visit(customBlock: child)
            case let child as ParagraphNode: return visit(paragraph: child)
            case let child as HeadingNode: return visit(heading: child)
            case let child as ThematicBreakNode: return visit(thematicBreak: child)
            case let child as TextNode: return visit(text: child)
            case let child as SoftBreakNode: return visit(softBreak: child)
            case let child as LineBreakNode: return visit(lineBreak: child)
            case let child as CodeNode: return visit(code: child)
            case let child as HtmlInlineNode: return visit(htmlInline: child)
            case let child as CustomInlineNode: return visit(customInline: child)
            case let child as EmphasisNode: return visit(emphasis: child)
            case let child as StrongNode: return visit(strong: child)
            case let child as LinkNode: return visit(link: child)
            case let child as ImageNode: return visit(image: child)
            default:
                assertionFailure("Unexpected child")
                return nil
            }
        }
    }
}

extension Visitor where Result: VisitorResult {
    public func visit(document node: DocumentNode) -> Result {
        visitChildren(of: node).joined()
    }

    public func visit(blockQuote node: BlockQuoteNode) -> Result {
        visitChildren(of: node).joined()
    }

    public func visit(list node: ListNode) -> Result {
        visitChildren(of: node).joined()
    }

    public func visit(item node: ItemNode) -> Result {
        visitChildren(of: node).joined()
    }

    public func visit(codeBlock node: CodeBlock) -> Result {
        visitChildren(of: node).joined()
    }

    public func visit(htmlBlock node: HtmlBlockNode) -> Result {
        visitChildren(of: node).joined()
    }

    public func visit(customBlock node: CustomBlockNode) -> Result {
        visitChildren(of: node).joined()
    }

    public func visit(paragraph node: ParagraphNode) -> Result {
        visitChildren(of: node).joined()
    }

    public func visit(heading node: HeadingNode) -> Result {
        visitChildren(of: node).joined()
    }

    public func visit(thematicBreak node: ThematicBreakNode) -> Result {
        visitChildren(of: node).joined()
    }

    public func visit(softBreak node: SoftBreakNode) -> Result {
        visitChildren(of: node).joined()
    }

    public func visit(lineBreak node: LineBreakNode) -> Result {
        visitChildren(of: node).joined()
    }

    public func visit(code node: CodeNode) -> Result {
        visitChildren(of: node).joined()
    }

    public func visit(htmlInline node: HtmlInlineNode) -> Result {
        visitChildren(of: node).joined()
    }

    public func visit(customInline node: CustomInlineNode) -> Result {
        visitChildren(of: node).joined()
    }

    public func visit(emphasis node: EmphasisNode) -> Result {
        visitChildren(of: node).joined()
    }

    public func visit(strong node: StrongNode) -> Result {
        visitChildren(of: node).joined()
    }

    public func visit(link node: LinkNode) -> Result {
        visitChildren(of: node).joined()
    }

    public func visit(image node: ImageNode) -> Result {
        visitChildren(of: node).joined()
    }
}

extension Array where Element: VisitorResult {
    public func joined() -> Element {
        reduce(.empty(), +)
    }
}
