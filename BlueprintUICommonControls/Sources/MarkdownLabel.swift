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

    func set(markdown string : String, with style : Any) {
        guard self.rawMarkdown != string else {
            return
        }
        
        
    }

    private static var rawMarkdownKey = NSObject()

    private var rawMarkdown : String? {
        get { objc_getAssociatedObject(self, &UILabel.rawMarkdownKey) as? String }
        set { objc_setAssociatedObject(self, &UILabel.rawMarkdownKey, newValue, .OBJC_ASSOCIATION_COPY) }
    }
}

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
        }
    }
}

