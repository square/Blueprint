//
//  MarkdownLabel.swift
//  BlueprintUICommonControls
//
//  Created by Kyle Van Essen on 6/28/21.
//

import BlueprintUI


public struct MarkdownLabel : UIViewElement {

    public typealias UIViewType = UILabel
    
    public static func makeUIView() -> UILabel {
        UILabel()
    }
    
    public func updateUIView(_ view: UILabel, with context: UIViewElementContext) {
        fatalError()
    }
}


extension UILabel {

    func set(markdown string : String, with style : Markdown.Style) {
        guard self.rawMarkdown != string else {
            return
        }
        
        // TODO...
    }

    private static var rawMarkdownKey = NSObject()

    private var rawMarkdown : String? {
        get { objc_getAssociatedObject(self, &UILabel.rawMarkdownKey) as? String }
        set { objc_setAssociatedObject(self, &UILabel.rawMarkdownKey, newValue, .OBJC_ASSOCIATION_COPY) }
    }
}

/// https://github.com/syntax-tree/mdast
/// https://daringfireball.net/projects/markdown/syntax
public struct Markdown {
    
    var contents : [Element]
    
    init(string : String) throws {
        fatalError()
    }
    
    init(contents : [Element]) throws {
        self.contents = contents
    }
}


extension Markdown {
    
    struct Element : Equatable {
        
        var kind : Kind
        
        var children : [Child]
        
        enum Child : Equatable {
            case characters(String)
            case element(Element)
        }
        
        enum Kind {
            case bold
            case italic
            case link
            case header
            case paragraph
            case linebreak
        }
    }
}


protocol MarkdownElementParser {
    
    static var kind : Markdown.Element.Kind { get }
    
    static func parse(from : Scanner) -> Any
    
}


extension Markdown {
    
    struct BoldParser {
        static func parse(from : Scanner) -> Any {
            
        }
    }
    
    final class Parser {
        
        init(_ string : String) {
            
        }
    }
}

