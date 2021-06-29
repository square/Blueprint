//
//  HTML.swift
//  HTMLLabel
//
//  Created by Kyle Van Essen on 12/24/20.
//

import UIKit


struct HTML : Equatable {
        
    var root : Tag
}


extension HTML {
    
    struct Tag : Equatable {
        
        init(
            name: String,
            attributes: [String : String]? = nil,
            children: [HTML.Tag.Child] = []
        ) {
            self.name = name
            self.attributes = attributes
            self.children = children
        }
        
        var name : String
        var attributes : [String:String]?
        
        var children : [Child]
                
        enum Child : Equatable {
            case characters(String)
            case tag(Tag)
        }
    }
}


extension HTML.Tag {
    static let rootName = "html-label-root"
    
    static func root(wrapping wrapped : () -> Self) -> Self {
        Self(name: self.rootName, children: [.tag(wrapped())])
    }
    
    static func root(with children : () -> [Child]) -> Self {
        Self(name: self.rootName, children: children())
    }
}


//
// MARK: Formatting
//


extension HTML  {
    struct Format : Equatable {
        var rootAttributes : RootFontAttributes
        var tagFormats : [Set<TagName> : Format]
        
        struct TagName : Hashable {
            
            // Eg, "b", "i", "strong", etc.
            let name : String
            
            // If the name is "b", this could be ["strong"].
            let synonyms : Set<String>
        }
        
        struct RootFontAttributes : Equatable {
            var pointSize : CGFloat
            var weight : UIFont.Weight
        }
        
        struct FontAttributes : Equatable {
            var pointSize : CGFloat?
            var weight : UIFont.Weight?
        }
    }
}


extension HTML.Tag {
    
    struct Format : Equatable {
        private var attributes : [NSAttributedString.Key:AnyEquatable]
        private var fontAttributes : HTML.Format.FontAttributes
        
        init(_ attributes : [NSAttributedString.Key:AnyEquatable]) {
            self.attributes = attributes
            self.fontAttributes = .init() // TODO
            fatalError()
        }
        
        func toStringAttributes() -> [NSAttributedString.Key:Any] {
            self.attributes.mapValues { $0.base }
        }
        
        struct AnyEquatable : Equatable {

            let base : Any
            
            let isEqual : (Any) -> Bool
            
            init<Value:Equatable>(_ value : Value) {
                self.base = value
                
                self.isEqual = { other in
                    (other as? Value) == value
                }
            }
            
            static func == (lhs: AnyEquatable, rhs: AnyEquatable) -> Bool {
                lhs.isEqual(rhs.base)
            }
        }
    }
}


//
// MARK: To Attributed Strings
//

extension HTML.Tag {
    
    func toAttributed(with format : HTML.Format) -> NSAttributedString {
        
        guard self.children.isEmpty == false else {
            return NSAttributedString()
        }
        
        let base = NSMutableAttributedString()
        
        self.appendTo(base, format: format, context: Context(parents: []))
        
        return base
    }
    
    private func appendTo(_ string : NSMutableAttributedString, format : HTML.Format, context : Context) {
        
        self.children.forEach {
            let context = context.modified {
                $0.parents.append(self.name)
            }
            
            $0.appendTo(string, format: format, context: context)
        }
    }
    
    struct Context {
        var parents : [String]
        
        func modified(_ block : (inout Context) -> ()) -> Self {
            var copy = self
            block(&copy)
            return copy
        }
    }
}


extension HTML.Tag.Child {
    
    func appendTo(_ string : NSMutableAttributedString, format : HTML.Format, context : HTML.Tag.Context) {
        
        switch self {
        case .characters(let characters):
            let attributed = NSAttributedString(string: characters, attributes: nil) // TODO
            
            string.append(attributed)
            
        case .tag(let tag):
            tag.appendTo(string, format: format, context: context)
        }
    }
}

