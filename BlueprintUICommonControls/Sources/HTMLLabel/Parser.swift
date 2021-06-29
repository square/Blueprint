//
//  Parser.swift
//  HTMLLabel
//
//  Created by Kyle Van Essen on 12/24/20.
//

import Foundation


extension HTMLLabel {
    
    final class Parser : NSObject, XMLParserDelegate {
                
        private let input : String
        
        init(html input : String) {
            self.input = input
            
            super.init()
        }
        
        //
        // MARK: Parsing
        //
        
        private enum State {
            case new
            case beganDocument
            case parsing(root : Tag)
            case endedDocument(root : Tag?)
            case error(Error)
        }
        
        // TODO: Clear cache after some point?
        private static var cache : [String:HTML.Tag?] = [:]
        
        static func parse(html : String) throws -> HTML.Tag?  {
            
            if let cached = Self.cache[html] {
                return cached
            } else {
                let tag = try Parser(html: html).parse()
                
                Self.cache[html] = tag
                
                return tag
            }
        }
        
        private var state : State = .new
        
        func parse() throws -> HTML.Tag? {
            guard case .new = self.state else {
                fatalError()
            }
                    
            let parser = try XMLParser(data: Self.preprocess(html: self.input))
            parser.delegate = self
            
            parser.parse()
            
            switch self.state {
            case .new: fatalError()
            case .beganDocument: fatalError()
            case .parsing(_): fatalError()
            case .endedDocument(root: let root): return root?.toHTMLTag()
            case .error(let error): throw error
            }
        }
        
        //
        // MARK: Preprocessing
        //
        
        static func preprocess(html : String) throws -> Data {
            
            let html = "<\(HTML.Tag.rootName)>" + html + "</\(HTML.Tag.rootName)>"
            
            guard let data = html.data(using: .utf8) else {
                throw Error.couldNotConvertToUTF8
            }
            
            return data
        }
        
        //
        // MARK: XMLParserDelegate
        //
            
        func parserDidStartDocument(_ parser: XMLParser) {
            self.state = .beganDocument
        }
        
        func parserDidEndDocument(_ parser: XMLParser) {
            
            switch self.state {
            case .new: fatalError()
            case .beganDocument: self.state = .endedDocument(root: nil)
            case .parsing(let root): self.state = .endedDocument(root: root)
            case .endedDocument(_): fatalError()
            case .error(_): break
            }
        }
        
        private var currentTag : Tag?
            
        func parser(
            _ parser: XMLParser,
            foundCharacters string: String
        ) {
            guard let tag = self.currentTag else {
                fatalError()
            }
            
            tag.children.append(.characters(string))
        }
        
        func parser(
            _ parser: XMLParser,
            didStartElement elementName: String,
            namespaceURI: String?,
            qualifiedName qName: String?,
            attributes : [String : String] = [:]
        ) {
            let tag = Tag(parent: self.currentTag, name: elementName, attributes: attributes)
            
            switch self.state {
            case .new: fatalError()
            case .beganDocument: self.state = .parsing(root: tag)
            case .parsing(_): break
            case .endedDocument(_): fatalError()
            case .error(_): fatalError()
            }
            
            if let current = self.currentTag {
                current.children.append(.tag(tag))
                self.currentTag = tag
            } else {
                self.currentTag = tag
            }
        }
        
        func parser(
            _ parser: XMLParser,
            didEndElement elementName: String,
            namespaceURI: String?,
            qualifiedName qName: String?
        ) {
            self.currentTag = self.currentTag?.parent
        }
        
        func parser(_ parser: XMLParser, parseErrorOccurred parseError: Swift.Error) {
            parser.abortParsing()
            
            self.state = .error(.parseError(parseError))
        }
    }
}


extension HTMLLabel.Parser {
    
    enum Error : Swift.Error {
        case couldNotConvertToUTF8
        case parseError(Swift.Error)
    }
}


extension HTMLLabel.Parser {
    
    final class Tag {
        
        init(
            parent: Tag?,
            name : String,
            attributes : [String:String]
        ) {
            self.parent = parent
            self.name = name
            self.attributes = attributes
        }
        
        private(set) weak var parent : Tag?
        
        let name : String
        let attributes : [String:String]
        
        fileprivate(set) var children : [Child] = []
        
        enum Child {
            case characters(String)
            case tag(Tag)
            
            func toHTMLChild() -> HTML.Tag.Child {
                switch self {
                case .characters(let string): return .characters(string)
                case .tag(let child): return .tag(child.toHTMLTag())
                }
            }
        }
        
        func toHTMLTag() -> HTML.Tag {
            HTML.Tag(
                name: self.name,
                attributes: self.attributes,
                children: self.children.map { $0.toHTMLChild() }
            )
        }
    }
    
}
