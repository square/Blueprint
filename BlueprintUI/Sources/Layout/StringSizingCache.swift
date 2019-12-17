//
//  StringSizingCache.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 12/16/19.
//

import Foundation


public final class StringSizingCache
{
    public static let `default` = StringSizingCache()
    
    public init() {}
    
    private var cache : [Entry:CGSize] = [:]
    
    public func size(with size : CGSize, string : NSAttributedString, numberOfLines : Int) -> CGSize
    {
        let entry = Entry(size: size, string: string, numberOfLines: numberOfLines)
        
        if let existing = self.cache[entry] {
            return existing
        } else {
            let size = entry.measure()
            
            self.cache[entry] = size
            
            return size
        }
    }
}

extension StringSizingCache
{
    struct Entry : Hashable
    {
        public let size : CGSize
        
        public let string : NSAttributedString
        public let numberOfLines : Int
            
        public init(size : CGSize, string : NSAttributedString, numberOfLines : Int)
        {
            self.size = size
            self.string = string.copy() as! NSAttributedString
            self.numberOfLines = numberOfLines
            
            var hasher = Hasher()
            self.size.width.hash(into: &hasher)
            self.size.height.hash(into: &hasher)
            self.string.hash(into: &hasher)
            self.numberOfLines.hash(into: &hasher)

            self.hashCode = hasher.finalize()
        }
        
        private let hashCode : Int
        
        func hash(into hasher: inout Hasher)
        {
            self.hashCode.hash(into: &hasher)
        }
        
        /**
         Keep around a label to use for measurement and sizing.
         
         We would usually do this using NSString or NSAttributedString's boundingRect family of methods,
         but these do not let you specify a `numberOfLines` parameter, which is critical to correct sizing.
         
         As such, we will allocate this label once and then use it to measure by setting its text and attributes.
         */
        private static let measuringLabel = UILabel()
        
        public func measure() -> CGSize
        {
            let label = Entry.measuringLabel
            
            label.attributedText = self.string
            label.numberOfLines = self.numberOfLines
            
            return label.sizeThatFits(self.size)
        }
    }
}
